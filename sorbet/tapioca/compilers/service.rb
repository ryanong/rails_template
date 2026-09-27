# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      # Generates RBI stubs for classes that include the +Service+ concern.
      #
      # For each service class it emits:
      #   - A nested +Job < ::Service::ServiceJob+ class
      #   - A nested +Error < ::StandardError+ class
      #   - A typed singleton +.call+ method whose parameters mirror the
      #     service's +#initialize+ (or +T::Struct+ props) and whose return
      #     type matches the Sorbet sig on the instance +#call+ method directly.
      #     Falls back to +T.untyped+ when no sig exists.
      #
      # Example — given:
      #
      #   class SendSms
      #     include Service
      #
      #     sig { params(phone_number: String, message: String).void }
      #     def initialize(phone_number, message) = ...
      #
      #     sig { override.void }
      #     def call = ...
      #   end
      #
      # The compiler produces:
      #
      #   class SendSms
      #     class Error < ::StandardError; end
      #     class Job < ::Service::ServiceJob; end
      #
      #     sig { params(phone_number: String, message: String).void }
      #     def self.call(phone_number, message); end
      #
      #     sig { params(phone_number: String, message: String).returns(T.nilable(::SendSms::Job)) }
      #     def self.enqueue(phone_number, message); end
      #
      #     sig { params(time: T.untyped, phone_number: String, message: String).returns(T.nilable(::SendSms::Job)) }
      #     def self.enqueue_at(time, phone_number, message); end
      #   end
      #
      # +::Service::Result[T.noreturn]+ is added to the return union only when
      # +#runnable?+ has been overridden on the service class OR its declared
      # return type is not +TrueClass+ — meaning the failure path in
      # +ClassMethods#call+ can actually be reached.
      #
      class Service < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(Object) } }

        sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
        def self.gather_constants
          all_classes.select { |klass| klass < ::Object && klass.ancestors.include?(::Service) }
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            klass.create_class("Job", superclass_name: "::Service::ServiceJob")
            klass.create_class("Error", superclass_name: "::StandardError")

            parameters = compile_parameters
            job_type = "T.nilable(::#{constant.name}::Job)"

            klass.create_method(
              "call",
              parameters: parameters,
              return_type: call_result_type,
              class_method: true
            )

            klass.create_method(
              "enqueue",
              parameters: parameters,
              return_type: job_type,
              class_method: true
            )

            klass.create_method(
              "enqueue_at",
              parameters: [ create_param("time", type: "::Time") ] + parameters,
              return_type: job_type,
              class_method: true
            )

            proc_result_type = after_call_proc_result_type
            klass.create_constant(
              "AfterCallProc",
              value: "T.type_alias { T.proc.params(result: #{proc_result_type}).void }"
            )

            klass.create_method(
              "after_call",
              parameters: [
                create_kw_opt_param("callable", type: "T.any(::Service, AfterCallProc, ::NilClass)", default: "T.unsafe(nil)"),
                create_block_param("block", type: "T.nilable(AfterCallProc)")
              ],
              return_type: "void",
              class_method: true
            )

            hooks_type = "T::Array[T.any(::Service, AfterCallProc)]"

            klass.create_method(
              "hooks",
              parameters: [],
              return_type: hooks_type,
              class_method: true
            )

            klass.create_method(
              "hooks=",
              parameters: [ create_param("hooks", type: hooks_type) ],
              return_type: "void",
              class_method: true
            )
          end
        end

        private

        sig { returns(String) }
        def call_result_type
          call_sig = T::Utils.signature_for_method(constant.instance_method(:call))

          if always_runnable?
            # Always runnable — mirror #call's return type exactly, preserving void.
            call_sig_return_type(call_sig)
          else
            # void cannot appear inside T.any(...), so map it to NilClass.
            inner = call_sig_inner_type(call_sig)
            "T.any(#{inner}, ::Service::Result[T.noreturn])"
          end
        end

        # Return-type string used as the result param of AfterCallProc.
        # Mirrors call_sig_inner_type: void is mapped to NilClass because
        # void cannot appear as a proc parameter type.
        sig { returns(String) }
        def after_call_proc_result_type
          call_sig = T::Utils.signature_for_method(constant.instance_method(:call))
          call_sig_inner_type(call_sig)
        end

        # Raw return-type string for #call, used when runnable? is always true.
        # Preserves "void" so Tapioca emits .void rather than .returns(NilClass).
        sig { params(call_sig: T.untyped).returns(String) }
        def call_sig_return_type(call_sig)
          return "T.untyped" unless call_sig
          return "void" if call_sig.return_type.is_a?(T::Private::Types::Void)

          call_sig.return_type.name
        end

        # Return-type string for the success branch when inside T.any(...).
        # void cannot appear inside T.any(...), so it is mapped to NilClass.
        sig { params(call_sig: T.untyped).returns(String) }
        def call_sig_inner_type(call_sig)
          return "T.untyped" unless call_sig
          return "NilClass" if call_sig.return_type.is_a?(T::Private::Types::Void)

          call_sig.return_type.name
        end

        TrueReturn = T::Types::Simple.new(TrueClass)

        sig { returns(T::Boolean) }
        def always_runnable?
          runnable_method = constant.instance_method(:runnable?)
          runnable_sig = T::Utils.signature_for_method(runnable_method)
          runnable_sig&.return_type == TrueReturn
        end

        sig { returns(T::Array[RBI::TypedParam]) }
        def compile_parameters
          return compile_struct_parameters if t_struct?

          compile_initialize_parameters
        end

        # For T::Struct subclasses, read props directly rather than parsing
        # the dynamically-generated #initialize, which carries no Sorbet sig.
        sig { returns(T::Array[RBI::TypedParam]) }
        def compile_struct_parameters
          required = []
          optional = []

          T.cast(constant, T.class_of(T::Struct)).props.each do |name, rules|
            type_str = rules[:type_object].name
            name_str = name.to_s
            has_default = rules.key?(:default) || rules.key?(:factory)

            if has_default
              optional << create_kw_opt_param(name_str, type: type_str, default: "T.unsafe(nil)")
            else
              required << create_kw_param(name_str, type: type_str)
            end
          end

          required + optional
        end

        sig { returns(T::Boolean) }
        def t_struct?
          T.must(constant < T::Struct)
        end

        sig { returns(T::Array[RBI::TypedParam]) }
        def compile_initialize_parameters
          method = constant.instance_method(:initialize)

          # Sorbet wraps methods with a generic (*args, **, &blk) wrapper at
          # runtime, so method.parameters returns the wrapper's params rather
          # than the original ones. Prefer the Sorbet signature when present —
          # sig.parameters gives the original names/kinds, and sig.arg_types /
          # sig.kwarg_types give the declared types (each entry: [name, type]).
          sorbet_sig = T::Utils.signature_for_method(method)

          params = sorbet_sig ? sorbet_sig.parameters : method.parameters
          type_map = build_type_map(sorbet_sig)

          params.filter_map do |kind, name|
            type_str = type_map.fetch(name, "T.untyped")
            name_str = name.to_s
            case kind
            when :req
              create_param(name_str, type: type_str)
            when :opt
              create_opt_param(name_str, type: type_str, default: "T.unsafe(nil)")
            when :keyreq
              create_kw_param(name_str, type: type_str)
            when :key
              create_kw_opt_param(name_str, type: type_str, default: "T.unsafe(nil)")
            when :rest
              create_rest_param(name_str.empty? ? "args" : name_str, type: type_str)
            when :keyrest
              create_kw_rest_param(name_str.empty? ? "kwargs" : name_str, type: type_str)
            when :block
              create_block_param(name_str.empty? ? "block" : name_str, type: "T.nilable(Proc)")
            end
          end
        end

        # Builds a symbol → type-string lookup from the positional and keyword
        # entries in a Sorbet signature. Returns an empty hash when no sig exists.
        sig { params(sorbet_sig: T.untyped).returns(T::Hash[Symbol, String]) }
        def build_type_map(sorbet_sig)
          return {} unless sorbet_sig

          type_map = {}
          sorbet_sig.arg_types.each { |name, type| type_map[name] = type.name }
          sorbet_sig.kwarg_types.each { |name, type| type_map[name] = type.name }
          type_map
        end
      end
    end
  end
end

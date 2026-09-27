# typed: strict
# frozen_string_literal: true

require "capybara/experience"
Dir[Rails.root.join("test/support/experiences/**/*.rb")].each { |f| require f }

module Tapioca
  module Dsl
    module Compilers
      class CapybaraExperience < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::Capybara::Experience) } }

        sig { override.returns(T::Enumerable[T::Module[T.anything]]) }
        def self.gather_constants
          all_classes.select { |klass| klass < ::Capybara::Experience }
        end

        sig { override.void }
        def decorate
          name = constant.name
          return unless name

          method_name = T.must(name.split("::").last)
          init = constant.instance_method(:initialize)
          parameters = compile_parameters(init)
          return_type = "::#{name}"

          root.create_path(::Capybara::Experience::DSL) do |mod|
            mod.create_method(method_name, parameters: parameters, return_type: return_type)
          end
        end

        private

        POSITIONAL_KINDS = [ :req, :opt, :rest ].freeze

        sig { params(method: UnboundMethod).returns(T::Array[RBI::TypedParam]) }
        def compile_parameters(method)
          params = method.parameters.filter_map do |kind, name|
            name = name.to_s
            case kind
            when :req
              create_param(name, type: "T.untyped")
            when :opt
              create_opt_param(name, type: "T.untyped", default: "T.unsafe(nil)")
            when :keyreq
              create_kw_param(name, type: "T.untyped")
            when :key
              create_kw_opt_param(name, type: "T.untyped", default: "T.unsafe(nil)")
            when :rest
              create_rest_param("args", type: "T.untyped")
            when :keyrest
              create_kw_rest_param("kwargs", type: "T.untyped")
            end
          end

          params << create_block_param("block", type: "T.nilable(Proc)")
          params
        end
      end
    end
  end
end

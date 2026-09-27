# typed: strict
# frozen_string_literal: true

module Service
  class Result
    extend T::Helpers
    extend T::Generic

    Elem = type_member

    # Returns a successful result wrapping the given value.
    #
    # Example:
    #
    #   Service::Result.success(123)
    #     # => #<Service::Result value: 123>
    #
    sig do
      type_parameters(:T)
        .params(value: T.type_parameter(:T))
        .returns(Result[T.type_parameter(:T)])
    end
    def self.success(value)
      new(success: true, value:, error: nil)
    end

    # Returns a failed result wrapping the given error.
    #
    # Because the failure carries no value, the result type is Result[T.noreturn]
    # which is a subtype of Result[T] for any T (by covariance of type members).
    #
    # Example:
    #
    #   Service::Result.failure(RuntimeError.new("oops"))
    #     # => #<Service::Result error: #<RuntimeError: oops>>
    #
    sig do
      type_parameters(:T)
        .params(value: T.type_parameter(:T), error: StandardError)
        .returns(Result[T.type_parameter(:T)])
    end
    def self.failure(value, error:)
      new(success: false, value:, error:)
    end

    sig { params(success: T::Boolean, value: T.nilable(Elem), error: T.nilable(StandardError)).void }
    def initialize(success:, value:, error:)
      @success = success
      @value = value
      @error = error
    end

    sig { returns(String) }
    def to_s
      if ok?
        "#<Service::Result:0x%x value: %s>" % [ object_id, T.unsafe(@value).inspect ]
      else
        "#<Service::Result:0x%x error: %s>" % [ object_id, T.must(@error).inspect ]
      end
    end

    alias_method :inspect, :to_s

    # If the result represents a value, invokes the supplied block with
    # that value.
    #
    # If the result represents an error, returns self.
    #
    # The block must also return a Service::Result object.
    # Use #map otherwise.
    #
    # Example:
    #
    #   result = do_something().then { |val|
    #     do_other_thing(val)
    #   }
    #     # => #<Service::Result value: ...>
    #
    #   do_something_that_fails().then { |val|
    #     # never invoked
    #   }
    #     # => #<Service::Result error: ...>
    #
    sig do
      type_parameters(:U)
        .params(blk: T.proc.params(arg0: Elem).returns(Result[T.type_parameter(:U)]))
        .returns(Result[T.type_parameter(:U)])
    end
    def then(&blk)
      if ok?
        blk.call(T.cast(@value, Elem))
      else
        T.cast(self, Result[T.type_parameter(:U)])
      end
    end

    # If the result represents an error, invokes the supplied block with that error.
    #
    # If the result represents a value, returns self.
    #
    # The block must also return a Service::Result object.
    # Use #map otherwise.
    #
    # Example:
    #   result = do_something().rescue { |val, error|
    #     # never invoked
    #   }
    #     # => #<Service::Result value: ...>
    #
    #   result = do_something().rescue(SpecificError) { |val, error|
    #     # only invoked if the error is a SpecificError
    #   }
    #     # => #<Service::Result value: ...>
    #
    #   do_something_that_fails().rescue { |val, error|
    #     # handle_error(val)
    #   }
    #     # => #<Service::Result error: ...>
    #
    sig do
      type_parameters(:U)
        .params(error_class: T.class_of(StandardError), blk: T.proc.params(arg0: T.nilable(Elem), arg1: StandardError).returns(Result[T.type_parameter(:U)]))
        .returns(Result[T.type_parameter(:U)])
    end
    def rescue(error_class = StandardError, &blk)
      return T.cast(self, Result[T.type_parameter(:U)]) if ok?

      if T.must(@error).is_a?(error_class)
        blk.call(@value, T.must(@error))
      else
        T.cast(self, Result[T.type_parameter(:U)])
      end
    end

    # If the result represents a value, invokes the supplied block with that
    # value and wraps the block's return value in a Service::Result.
    #
    # If the result represents an error, returns self.
    #
    # The block should not return a Service::Result object (unless you
    # truly intend to create a Service::Result<Service::Result<T>>).
    # Use #then if it does.
    #
    # Example:
    #
    #   result = do_something()
    #     # => #<Service::Result value: 123>
    #
    #   result.map { |val| val * 2 }
    #     # => #<Service::Result value: 246>
    #
    #   do_something_that_fails().map { |val|
    #     # never invoked
    #   }
    #     # => #<Service::Result error: ...>
    #
    sig do
      type_parameters(:U)
        .params(blk: T.proc.params(arg0: Elem).returns(T.type_parameter(:U)))
        .returns(Result[T.type_parameter(:U)])
    end
    def map(&blk)
      if ok?
        Result.success(blk.call(T.cast(@value, Elem)))
      else
        T.cast(self, Result[T.type_parameter(:U)])
      end
    end

    # If the result represents a value, returns that value.
    #
    # If the result represents an error, invokes the supplied block with the
    # exception object.
    #
    # Example:
    #
    #   result = do_something()
    #     # => #<Service::Result value: "foo">
    #
    #   result.value { "nope" }
    #     # => "foo"
    #
    #   result = do_something_that_fails()
    #     # => #<Service::Result error: ...>
    #
    #   result.value { "nope" }
    #     # => "nope"
    #
    sig do
      type_parameters(:U)
        .params(blk: T.proc.params(args0: T.nilable(Elem), arg1: StandardError).returns(T.type_parameter(:U)))
        .returns(T.any(T.nilable(Elem), T.type_parameter(:U)))
    end
    def value(&blk)
      if ok?
        T.cast(@value, Elem)
      else
        blk.call(@value, T.must(@error))
      end
    end

    # If the result represents a value, returns that value.
    #
    # If the result represents an error, raises that error.
    #
    # Example:
    #
    #   result = do_something()
    #     # => #<Service::Result value: "foo">
    #
    #   result.value!
    #     # => "foo"
    #
    #   result = do_something_that_fails()
    #     # => #<Service::Result error: ...>
    #
    #   result.value!
    #     # !! raises exception
    #
    sig { returns(Elem) }
    def value!
      raise T.must(@error) unless ok?

      T.cast(@value, Elem)
    end

    # Returns true if the result represents a value, false if an error.
    #
    # Example:
    #
    #   result = do_something()
    #     # => #<Service::Result value: "foo">
    #
    #   result.ok?
    #     # => true
    #
    #   result = do_something_that_fails()
    #     # => #<Service::Result error: ...>
    #
    #   result.ok?
    #     # => false
    #
    sig { returns(T::Boolean) }
    def ok?
      @success
    end

    # If the result represents a value, returns nil.
    #
    # If the result represents an error, returns that error.
    #
    #   result = do_something()
    #     # => #<Service::Result value: "foo">
    #
    #   result.error
    #     # => nil
    #
    #   result = do_something_that_fails()
    #     # => #<Service::Result error: ...>
    #
    #   result.error
    #     # => ...
    #
    sig { returns(T.nilable(StandardError)) }
    def error
      @error
    end
  end
end

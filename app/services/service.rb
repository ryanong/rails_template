# typed: false

require "active_job/arguments"

module Service
  extend ActiveSupport::Concern
  include ActionPolicy::Behaviour

  NotRunnableError = Class.new(StandardError)

  # Tighten to T.nilable(User) once the app has a User model.
  sig { returns(T.untyped) }
  attr_reader :actor

  class ServiceJob < ApplicationJob
    queue_as :default

    class_attribute :service_class
    def perform(*args)
      self.class.service_class.call(*args)
    end
  end

  included do
    self::Job = Class.new(ServiceJob)
    self::Job.service_class = self
    self::Error = Class.new(StandardError)

    authorize :user, through: :actor
    self.hooks = []
  end

  module ClassMethods
    attr_accessor :hooks

    def call(*args, **kwargs)
      service = kwargs.empty? ? new(*args) : new(*args, **kwargs)
      return Result.failure(NotRunnableError.new) unless service.runnable?
      service.call.tap do |result|
        run_after_call_hooks(result)
      end
    end

    def enqueue(*args, **kwargs)
      service = kwargs.empty? ? new(*args) : new(*args, **kwargs)
      if service.runnable?
        kwargs.empty? ? self::Job.perform_later(*args) : self::Job.perform_later(*args, **kwargs)
      end
    end

    def enqueue_at(time, *args, **kwargs)
      service = kwargs.empty? ? new(*args) : new(*args, **kwargs)
      if service.runnable?
        kwargs.empty? ? self::Job.set(wait_until: time).perform_later(*args) : self::Job.set(wait_until: time).perform_later(*args, **kwargs)
      end
    end

    def after_call(callable = nil, &block)
      if (callable.nil? && block.nil?) || (callable && block)
        raise ArgumentError, "Must provide a callable object or a block"
      end
      self.hooks << (callable || block)
    end

    def run_after_call_hooks(result)
      hooks.each do |hook|
        hook.call(result)
      end
    end
  end

  sig { returns(TrueClass) }
  def runnable?
    true
  end

  sig { params(record: T.untyped, to: T.nilable(Symbol), kwargs: T.untyped).void }
  def authorize!(record, to: service_policy_action, **kwargs)
    super(record, to:, **kwargs)
  end

  private

  sig { returns(Symbol) }
  def service_policy_action
    :"#{self.class.name.underscore}?"
  end

  sig { params(key: T.nilable(String), throw: T::Boolean, raise: T::Boolean, locale: T.nilable(Symbol), scope: T.nilable(Symbol), options: T::Hash[Symbol, T.untyped]).returns(String) }
  def t(key = nil, throw: false, raise: false, locale: nil, scope: "services.#{self.class.name.underscore}", **options)
    I18n.t(key, throw:, raise:, locale:, scope:, **options)
  end
end

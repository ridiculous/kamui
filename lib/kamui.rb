require "kamui/version"

module Kamui
  def self.included(base)
    base.include InstanceMethod
    super
  end

  def self.extended(base)
    return if base === self
    base.extend ClassMethod
    super
  end

  # Retry a block when certain errors are encountered
  # @param errors [*Array] one or many classes to rescue and retry
  # @param options [Hash]
  # @option :tries [Integer] number of times to retry (3)
  # @option :message [Regexp] scope the retry to errors with matching messages (nil)
  # @option :on_retry [Proc] before each retry, call this with the retry count and error, e.g. sleep 2*n (nil)
  # @option :fail [Bool] determines if error is raised after retries exhausted (true)
  # @param block [Proc] code to wrap in a retry
  def self.retry(*errors, **options, &block)
    build(errors, options).call(block)
  end

  class << self
    alias retries retry
  end

  def self.build(errors, options)
    errors = Array(errors)
    errors << StandardError if errors.empty?
    strategies[errors.first] || build_retry_strategy(errors, **options)
  end

  def self.strategies
    @@strategies ||= {}
  end

  # @option tries [Integer] the number of tries to run the block, where 3 actually means 3
  def self.build_retry_strategy(errors, message: nil, tries: 3, on_retry: nil, fail: true)
    ->(block) do
      retries = 0
      begin
        block.call
      rescue *errors => e
        if (retries += 1) < tries && (message.nil? || e.message =~ message)
          on_retry.call(retries, e) if on_retry
          retry
        elsif fail
          raise e
        end
      end
    end
  end

  module InstanceMethod
    # Retry a method or block when certain errors are encountered
    # @param errors [*Array<Class>] one or many classes to rescue and retry
    # @param options [Hash]
    # @option :tries [Integer] number of times to retry (3)
    # @option :message [Regexp] scope the retry to errors with matching messages (nil)
    # @option :on_retry [Proc] before each retry, call this with the retry count and error, e.g. sleep 2*n (nil)
    # @option :fail [Bool] determines if error is raised after retries exhausted (true)
    # @option :method [Symbol] method to call instead of a block
    # @option :args [Array] arguments to pass to :method option
    def retries(*errors, args: [], **options)
      if block_given?
        return Kamui.retry(*errors.flatten, **options) { yield }
      end
      case method_name = errors.shift
      when Symbol, String
        Kamui.retry(*errors.flatten, **options) { send(method_name, *args) }
      else
        raise "Kamui##{__method__} expects a method as it's first argument or a block"
      end
    end
  end

  module ClassMethod
    # Retry a method when certain errors are encountered
    # @todo Pass along block to method
    # @param method_name [Symbol] the method to retry
    # @param errors [*Array<Class>] one or many classes to rescue and retry
    # @param options [Hash]
    # @option :tries [Integer] number of times to retry (3)
    # @option :message [Regexp] scope the retry to errors with matching messages (nil)
    # @option :on_retry [Proc] before each retry, call this with the retry count and error, e.g. sleep 2*n (nil)
    # @option :fail [Bool] determines if error is raised after retries exhausted (true)
    def retries(method_name, *errors, **options)
      prepend(Module.new { define_method(method_name) { |*args| Kamui.retry(*errors.flatten, **options) { super(*args) } } })
    end
  end
end

require 'kamui/strategies'

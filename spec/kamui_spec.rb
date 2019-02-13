require "spec_helper"

Kamui.strategies.merge! test_errors: Kamui.build(StandardError, tries: 12)

RSpec.describe Kamui do
  let(:klass) do
    Class.new do
      include ::Kamui
      def call(arg = nil)
        case arg
        when String
          arg.upcase
        when Array
          call(arg.first)
        when Proc
          call(arg.call)
        when nil
          :ok
        end
      end
    end
  end

  describe 'Module functions' do
    it 'responds to retries' do
      expect(described_class).to respond_to(:retries)
    end

    it 'retries a block' do
      expect(described_class.retries { klass.new.call('hello') }).to eq 'HELLO'
    end
  end

  describe 'Mixin' do
    it 'retries an instance method N times before giving up' do
      expect(klass.new.call('hello')).to eq 'HELLO'
      expect(klass.new.retries(:call, args: ['bye'])).to eq 'BYE'
      expect(klass.new.retries(:call, :test_errors, args: -> { rand(100).even? ? raise : ['yo'] })).to eq 'YO'
    end

    it 'raises the error when attempts are exhausted' do

    end

    it 'does not raise the error when attempts are exhausted and :fail option is true' do

    end

    it 'retries a method with arguments' do

    end

    it 'retries a block when a block is given' do

    end
  end

  describe 'Extension' do
    before do
      klass.retries :call, :test_errors
    end

    it 'wraps an instance method with retry capability' do
      expect(klass.new.call('hello')).to eq 'HELLO'
      expect(klass.new.call(-> { rand(100).even? ? raise : 'yo' })).to eq 'YO'
    end
  end
end

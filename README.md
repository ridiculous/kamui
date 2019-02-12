# Kamui

Makes retrying methods and blocks super easy. Unobtrusively add retries without over complicating the method definition. Works as an extension, mixin or function.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kamui'
```

## Usage

The simplest usage is as a module function that accepts a block. If the use case allows for it, the most elegant and unobtrusive usage is as a class extension. Each variation accepts roughly the same arguments.

### Function

The Kamui module has a `retry` function (aliased to `retries`) which accepts a list of error classes, options and a block to retry.

```ruby
Kamui.retry(:network_errors) {}
Kamui.retry(Net::SSH::Disconnect) {}
Kamui.retry(ActiveRecord::StatementInvalid, message: /Deadlock/, on_retry: proc { |attempts| sleep 0.1 * attempts }) {}
```

### Extension

Extending Kamui defines a `retries` class method. The class method takes a method name, errors and options. The given method name is then wrapped with retry capability.

```ruby
class Example
  extend Kamui

  def call(*args)
    # do stuff ...
  end

  retries :call, :network_errors
end
```

### Mixin

Including Kamui defines a `retries` instance method. The method accepts either a method name or a block, along with the regular set of options.

```ruby
class Example
  include Kamui

  def call(*args)
    retries Net::SSH::Disconnect do
      # do stuff ...
    end
  end

  def optional_call(*args)
    retries :call, :network_errors, args: args
  end
end
```

When wrapping a method with `retries` a new `:args` option is available for passing along method arguments. Wrapping a method that accepts a block isn't supported as a mixin.

## Retry strategies

A retry strategy is simply a proc (or anything that responds to `call`). Commonly used retry strategies (such as `:network_errors`) can be registered with Kamui and referenced later when calling `retries`.

Register a strategy:

```ruby
Kamui.strategies.merge! deadlock: Kamui.build(ActiveRecord::StatementInvalid, tries: 10, message: /Deadlock/, on_retry: proc { |n| sleep 1 * n })
```

This creates a new retry strategy called `:deadlock` using `Kamui.build`, which provides the structure for a retry block (`begin...rescue`) and supports the established options.

Use a retry strategy by passing it's name in place of the specific error class:

```ruby
Kamui.retries(:deadlock) {}
Example.retries(:call, :deadlock) {}
Example.new.retries(:deadlock) {}
Example.new.retries(:call, :deadlock)
```

## Options

Kamui accepts the following set of options for modifying retry behavior:

```ruby
# :tries [Integer] number of times to retry (3)
# :message [Regexp] scope the retry to errors with matching messages (nil)
# :on_retry [Proc] before each retry, call this with the retry count and error, e.g. sleep 2*n (nil)
# :fail [Bool] determines if error is raised after retries exhausted (true)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ryan Buckley/kamui. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


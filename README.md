# Kamui

Makes retrying methods and blocks super easy! The Kamui gem provides a common retry structure and some options for modifying its behavior.

## Usage

Simply `include Kamui` and start using `retries`!

```ruby
class Example
  include Kamui

  def call(*args)
    retries Net::SSH::Disconnect do
      puts "do stuff ..."
    end
  end

  def optional_call(*args)
    retries :call, :network_errors, args: args, on_retry: proc { |n| sleep 2**n }
  end

  def cancel(&block)
    puts "yielding stuff ..."
    yield
  end

  retries :cancel, on_retry: ->(attempts, e) { puts "Retrying #{attempts}x for #{e.class}" }
end
```

## Options

Kamui accepts the following set of options for modifying retry behavior:

```ruby
# :tries [Integer] number of times to retry (3)
# :message [Regexp] scope the retry to errors with matching messages (nil)
# :on_retry [Proc] before each retry, call this with the retry count and error, e.g. sleep 2*n (nil)
# :fail [Bool] determines if error is raised after retries exhausted (true)
```

## Retry strategies

Strategies are defined and referenced by name (Symbol). Each strategy is simply a proc (or anything that responds to `call`). Commonly used retry strategies (such as `:network_errors`) can be registered with Kamui and referenced later when calling `retries`.

Register a strategy:

```ruby
strategy = Kamui.build(ActiveRecord::StatementInvalid, tries: 10, message: /Deadlock/)
Kamui.strategies.merge! deadlock: strategy
```

This creates a new retry strategy called `:deadlock` using `Kamui.build`, which provides the structure for a retry block (`begin...rescue`) and supports the established options.

Use a retry strategy by passing it's name in place of the specific error class:

```ruby
Example.retries(:call, :deadlock) { }
Example.new.retries(:deadlock) { }
Example.new.retries(:call, :deadlock)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ryan Buckley/kamui. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


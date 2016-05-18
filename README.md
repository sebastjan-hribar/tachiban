# Tachiban

Tachiban provides simple password hashing for user authentication with bcrypt.
The module provides methods for generating password hash and salt, password reset sent time and
a token in a form of random URL-safe base64 string to use for password reset links. It also provides
a method for user authentication.

The Tachiban code was extracted from a Hanami based web app using Hanami::Model and was also used in a Camping based web app using Active Record.

Though derived from a Hanami web app, Tachiban is currently not bound to Hanami.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tachiban'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tachiban

## Usage

Suppose we have a user model for which we want to provide password authentication.

#### Example:
__model__: User

__attributes__: name, surname, email, password_hash, password_salt,
                password_confirmation, password_reset_token, password_reset_sent_at

1. User creation


* generate password salt

```ruby
generate_pass_salt
```

* generate password hash

```ruby
generate_pass_hash(password, salt)
```


2. User authentication

```ruby
authenticated?(user_pass_hash, user_salt, input_pass)
```

3. Password reset setup

```ruby
password_reset_sent_at
token
```


### Specific for Hanami

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tachiban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
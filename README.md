# Tachiban

[![Join the chat at https://gitter.im/sebastjan-hribar/tachiban](https://badges.gitter.im/sebastjan-hribar/tachiban.svg)](https://gitter.im/sebastjan-hribar/tachiban?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Tachiban (立ち番 - standing watch) provides simple authentication system by using bcrypt for password hashing and
offers the following functionalities (with methods listed below
  under Methods by features):
- Signup
- Login
- Authentication
- Password reset

The Tachiban code was extracted from a Hanami based web app using
Hanami::Model and was also used in a Camping based web app using Active Record.


<!--## Installation

 Add this line to your application's Gemfile:

```ruby
gem 'tachiban'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tachiban

And include it in you application:

```ruby
include Tachiban
```
For Hanami based apps include it in the controller
prepare block in the `application.rb`:

```ruby
controller.prepare do
  #...
  include Tachiban
end
``` -->

## Usage

#### Methods by features:

##### Signup
To generate hashed password

```ruby
hashed_password(password)
```
##### Login
To check the user's credentials

```ruby
authenticated?(input_pass)
```

To login the authenticated user and set the user object
 as `session[:current_user]`

```ruby
login
```
##### Authentication
To check whether the user is logged in
```ruby
check_for_logged_in_user
```



##### Password reset
To set the password reset sent time
```ruby
password_reset_sent_at
```

To generate a random url token
```ruby
token
```

### ToDo
1. Setup default title and body for password reset e-mail.
2. Include level based authorization checking.

<!-- ## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sebastjan-hribar/tachiban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

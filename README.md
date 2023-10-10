# Tachiban

[![Join the chat at https://gitter.im/sebastjan-hribar/tachiban](https://badges.gitter.im/sebastjan-hribar/tachiban.svg)](https://gitter.im/sebastjan-hribar/tachiban?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Gem Version](https://badge.fury.io/rb/tachiban.svg?kill_cache=1)](https://badge.fury.io/rb/tachiban)

Tachiban (立ち番 - standing watch) provides simple authentication system for [Hanami web applications](http://hanamirb.org/) by using Argon2 for password hashing and
offers the following functionalities (with methods listed below
  under Methods by features):
- Signup
- Login
- Authentication
- Session handling
- Password reset
- Authorization has been moved to [Rokku](https://github.com/sebastjan-hribar/rokku) 

## Installation

 Add this line to your application's Gemfile:

```ruby
gem 'tachiban'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tachiban

Tachiban is already setup to be included by your Hanami application:

```ruby
::Hanami::Controller.configure do
  prepare do
    include Hanami::Tachiban
  end
end
```

## Usage

### Prerequisites
Prior to logging in or authenticating the user, retrieve the entity from the
database and assign it to the instance variable of `@user`.

In addition to that, the user entity must have the following attributes:

* **token** (used to compose the password reset url and get the user from the database)
* **password_reset_sent_at** (set as `Time.now` to check the reset link validity)
* **hashed_pass** (to hold the generated hashed password)


### Usage

#### Signup
To create a user with a hashed password use the `hashed_password(password)`
method for the password and store it as the user's attribute `hashed_pass`.

*Example*

```ruby
# Create action for an entity
def call(params)
  password = params[:newuser][:password]
  hashed_pass = hashed_password(password)
  repository = UserRepository.new

  @user = repository.create(name: name, surname: surname, email: email,
  hashed_pass: hashed_pass))
end
```

#### Authentication and login
To authenticate a user use the `authenticated?(input_password)` method and log
them in with the `login` method. Authentication is successful if the user exists and passwords match.

The user is logged in by setting the user object ID as the `session[:current_user]`.
After the user is logged in the session start time is defined as
`session[:session_start_time] = Time.now`. A default flash message is also
assigned as 'You have been successfully logged in.'.

The `session[:session_start_time]` is then used by the `session_expired?`
method to determine whether the session has expired or not.

*Example of session creation for an entity*

```ruby
# Create action for an entity session
email = params[:entity_session][:email]
password = params[:entity_session][:password]

@user = EntityRepository.new.find_by_email(email)
login if authenticated?(password)
```

To check whether the user is logged in use the `check_for_logged_in_user` method.
If the user is not logged in the `logout` method takes over.


#### Session handling
Tachiban handles session expiration by checking if a session has
expired and then restarts the session start time if the session
is still valid or proceeds with the following if the session
has expired:

- setting the `session[:current_user]` to `nil`,
- a flash message is set: `flash[:failed_notice] = "Your session has expired"`,
- redirects to the `routes.root_path` which can be overwritten by assigning
a different url to @redirect_url.


The `session_expired?` method compares the session start time
increased for the defined `@validity_time` (set to 10 minutes
by default, but can be overwritten) with the current time.

`handle_session` method:
```ruby
  def handle_session
    if session_expired?
      @redirect_url ||= routes.root_path
      session[:current_user] = nil
      flash[:failed_notice] = "Your session has expired."
      redirect_to @redirect_url
    else
      restart_session_counter
    end
  end
```

*Example of session handling in a share code module*

```ruby
module Web
  module HandleSession

     def self.included(action)
       action.class_eval do
         before :handle_session
       end
     end

  end
end
```


#### Password reset
The password reset feature provides a few simple methods to generate a
token, email subject and body. It is also possible to specify and
check the validity of the password reset url.

```ruby
token # => "YbRucc8YUlFJrYYp04eQKQ"
```

```ruby
email_subject(SomeApp) # => "SomeApp -- password reset request"
```


Provide the base url, the token and the number and type of the time units
 for the validity of the link.

```ruby
body = email_body(base_url, url_token, 2, "hour")
# => "Visit this url to reset your password: http://localhost:2300/passwordupdate/asdasdasdaerwrw.
#     The url will be valid for 2 hour(s).")
```

The link validity must me specified in seconds. The method compares the
current time with the time when the password reset link was sent increased
by the link validity: `Time.now > @user.password_reset_sent_at + link_validity`

```ruby
password_reset_url_valid?(link_validity)
```

### Example of use in an application
[Using Tachiban with a Hanami app](https://sebastjan-hribar.github.io/programming/2021/09/03/tachiban-with-hanami.html)


### Changelog

#### 1.0.0

BCrypt was replaced by Argon2.


#### 0.8.0

Bug fix for determining the validity of the password update linke. Greater than instead of less than was used
to compare the time of the reset link email and the time when the user tries to update the password.


#### 0.7.0

Authorization was moved to a separate gem [Rokku](https://github.com/sebastjan-hribar/rokku).
Readme update.

Method: `Tachiban::login`
<br>Change:
Default flash message and redirect url provided.


#### 0.6.1

Dependency change for **rake** to ">= 12.3.3".


#### 0.6.0

Method: `Tachiban::login`
<br>Change:
`session[:current_user]` is not set as the user object, but as the user object id.
***
Method: `Tachiban::logout`
<br>Change:
Added `session.clear` to remove any other values upon logout.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sebastjan-hribar/tachiban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

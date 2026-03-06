# Tachiban

[![Join the chat at https://gitter.im/sebastjan-hribar/tachiban](https://badges.gitter.im/sebastjan-hribar/tachiban.svg)](https://gitter.im/sebastjan-hribar/tachiban?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Gem Version](https://badge.fury.io/rb/tachiban.svg?kill_cache=1)](https://badge.fury.io/rb/tachiban)

Tachiban (立ち番 - standing watch) provides simple authentication system for [Hanami 2.x web applications](http://hanamirb.org/) by using Argon2 for password hashing and
offers the following functionalities (with methods listed below
  under Methods by features):
- Signup
- Login
- Authentication
- Session handling
- Password reset
- Authorization has been moved to [Rokku](https://github.com/sebastjan-hribar/rokku) 

**Note:** For Hanami 1.3 support, see the [1.0.0 branch](https://github.com/sebastjan-hribar/tachiban/tree/1.0.0) or install Tachiban 1.0.


## 1. Installation

 Add this line to your application's Gemfile:

```ruby
gem 'tachiban'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tachiban


Tachiban 2.0 needs to be included in the action:

```ruby
# app/action.rb
# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"
require "tachiban"

module MyApplication
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]
    include Hanami::Tachiban

    handle_exception "ROM::TupleCountMismatchError" => :handle_not_found

    private

    def handle_not_found(request, response, exception)
      response.status = 404
      response.format = :html
      response.body = "Not found"
    end
  end
end
```

## 2. Usage

### 2.1 Prerequisites
Prior to logging in or authenticating the user, retrieve the entity from the
database and assign it to a variable (e.g. `user`), which you then pass to
the methods as required.

In addition to that, the user entity must have the following attributes:

* **token** (used to compose the password reset url and get the user from the database)
* **password_reset_sent_at** (set as `Time.now` to check the reset link validity)
* **hashed_pass** (to hold the generated hashed password)


### 2.2 Usage

#### 2.2.3 Signup
To create a user with a hashed password use the `hashed_password(password)`
method for the password and store it as the user's attribute `hashed_pass`.

*Example*

```ruby
# Create action for the user
def handle(request, response)
  password = request.params[:newuser][:password]
  hashed_pass = hashed_password(password)

  user = user_repo.create(name: name, surname: surname, email: email,
  hashed_pass: hashed_pass)
end
```

#### 2.2.4 Authentication and login
To authenticate a user use the `authenticated?(input_password, user)` method and log
them in with the `login(request, response, user_id, flash_message: nil, login_redirect_url: nil)` method.

Authentication is successful if the user exists and passwords match. It's possible to provide your own flash message and / or redirect url. Otherwise, the **default values** will be used (see the table below).

The user is logged in by setting the user object ID as the `request.session[:current_user]`.
After the user is logged in, the session start time is defined as
`request.session[:session_start_time] = Time.now`. A default flash message is also
assigned as 'You have been successfully logged in.'.

The `request.session[:session_start_time]` is then used by the `session_expired?(request, response)` method to determine whether the session has expired or not.

**_Example of session creation for an entity_**

```ruby
# Create action for the user session
email = request.params[:entity_session][:email]
password = request.params[:entity_session][:password]

user = user_repo.find_by_email(email) #required by login
login(request, response, user.id) if authenticated?(password, user)
```

To check whether a user is logged in, use the `check_for_logged_in_user(request, response)` method. If the user is not logged in, the `logout(request, response, logout_redirect_url: nil)` method takes over.


#### 2.2.5 Session handling
Tachiban handles session expiration by checking if a session has
expired and then restarts the session start time if the session
is still valid or proceeds with the following if the session
has expired:

- setting the `request.session[:current_user]` to `nil`,
- a flash message is set: `response.flash[:failed_notice] = "Your session has expired"`,
- redirects to the root path `/`, which can be overwritten.


The `session_expired?(request, validity_time: nil)` method compares the session start time
increased for the defined `validity_time` (set to 10 minutes
by default, but can be overwritten) with the current time.

`handle_session(request, response, redirect_url: nil)` method:
```ruby
  def handle_session(request, response, redirect_url: nil)
    if session_expired?(request)
      redirect_url ||= '/'
      request.session[:current_user] = nil
      response.flash[:failed_notice] ||= "Your session has expired."
      response.redirect_to redirect_url
    else
      restart_session_counter(request)
    end
  end
```

#### 2.2.6 Session handling in a share code module
It is possible to enable session handling in a share code module as provided by Hanami.
To do this, create an authentication module in **app/actions/authentication.rb**.
The example below shows also how to custom values to replace default values in
actions.

```ruby
module MyApplication
  module Actions
    module Authentication
      def self.included(action_class)
        action_class.class_eval do
          before :check_for_logged_in_user
          before :handle_session
        end
      end

      private

      def custom_handle_session_redirect_url
        '/login'
      end

      def custom_logout_redirect_url
        '/login'
      end

      def custom_login_redirect_url
        '/'
      end

      def custom_session_validity_time
        if ENV['HANAMI_ENV'] == 'test'
          600
        else
          1800
        end
      end
    end
  end
end
```
We can then simply include the `Authentication` module in actions, where required.

However, if we include this in the base action class, it will be available in all
actions and there is no need for separate includes in actions:

```ruby
#
#
module MyApplication
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]
    include Hanami::Tachiban
    include MyApplication::Actions::Authentication

    handle_exception "ROM::TupleCountMismatchError" => :handle_not_found

    private
#
#
```


**_Disabling the authentication shared module in specific actions_**

Sometimes we might not want to check for authenticated user. For example,
doing so in the `login` action will cause an infinite loop. There we can
disable the module by overwriting the desired methods in the action:

```ruby
private

def check_for_logged_in_user; end
def handle_session; end
```

#### 2.2.7 Password reset
The password reset feature provides a few simple methods to:
* generate a token, email subject and body (text and html part)
* specify and check the validity of the password reset url and
* set the default application name for the email subject (it can be
overwritten or set as a ENV variable).

The link validity must me specified in seconds. The method compares the
current time with the time when the password reset link was sent increased
by the link validity: `Time.now > user.password_reset_sent_at + link_validity`.


```ruby
token # => "YbRucc8YUlFJrYYp04eQKQ"
```

```ruby
email_subject("SomeApp") # => "SomeApp -- password reset request"
```

```ruby
password_reset_url_valid?(link_validity)
```



Provide the following values when building the email body: reset url, user's name,
link validity, time unit and optionally the application name. Below is an example of
html_body in a mailer class:

```ruby
html_body = email_body_html(
          reset_url: reset_url,
          user_name: "#{user.name} #{user.surname}",
          link_validity: 2,
          time_unit: "hour",
          app_name: nil
          )
```

### 3. Default values
There are a few default values set which can be overwritten. See the table below.

|Required by method      |Variable              |Default value                          |
|---                     |---                   |---                                    |
|login                   |flash_message         |'You have been successfully logged in.'|
|login                   |login_redirect_url    |'/'                                    |
|logout                  |logout_redirect_url   |'/login'                               |
|session_expired?        |validity_time         |600                                    |
|handle_session          |redirect_url          |'/'                                    |




### 4. Changelog

#### 2.0.0

**Breaking Changes:**
- Supports Hanami ~> 2.0 applications only.
- Method signatures updated: `login`, `logout`, `check_for_logged_in_user`, and `handle_session` now require `(request, response)` parameters.
- Methods `session_expired?` and `restart_session_counter` now require `(request)` parameter.
- Tachiban must be explicitly included in the base action: `include Hanami::Tachiban`.
- Tachiban 2.0.0 doesn't rely on instance variable like `@user` anymore. Instead, a `user` variable must be passed as an argument to a method.

For Hanami 1.3 support, use Tachiban 1.0.

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

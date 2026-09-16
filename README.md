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


Tachiban needs to be included in the action:

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

The `authenticated?` method now performs the same amount of work whether or not the email matches a
user, so response time does not reveal whether an account exists. It returns false for
a nil password or a user record with no stored hash.


#### 2.2.5 Session handling
Tachiban handles session expiration by checking if a session has
expired and then restarts the session start time if the session
is still valid or proceeds with the following if the session
has expired:

- setting the `request.session[:current_user]` to `nil`,
- a flash message is set: `response.flash[:failed_notice] = "Your session has expired"`,
- redirects to the root path `/`, which can be overridden.


The `session_expired?(request, validity_time: nil)` method compares the session start time
increased for the defined `validity_time` (set to 10 minutes
by default, but can be overridden) with the current time.

On expiry, `handle_session` clears the current user, sets
`response.flash[:failed_notice]` and redirects. The flash and the redirect url
are configurable — see section 3.


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


**_Disabling the authentication shared module methods in specific actions_**

Any action a logged-out user must be able to reach, should disable the
authentication. One such example would be the `login` action. If we check
for an authenticated user there, it will cause an infinite loop. So we
have to disable the authentication module methods by overriding
the desired methods in the action. Below is a concrete example for the
new action for `UserSessions`, which renders the login form when a user
visits the '/login' url:

```ruby
# frozen_string_literal: true

module Myapplication
  module Actions
    module UserSessions
      class New < Myapplication::Action

        def handle(request, response)
          request.session[:current_user] = nil
        end

        private

        def check_for_logged_in_user; end
        def handle_session; end
      end
    end
  end
end
```

#### 2.2.7 Password reset
The password reset feature provides methods to:
* generate a token, build email subject and body (text and html part),
* verify the reset link and
* invalidate a used token.

The link validity must me specified in seconds. The method compares the
current time with the time when the password reset link was sent increased
by the link validity: `Time.now > user.password_reset_sent_at + link_validity`.


**Generating a reset link**

```ruby
reset_token = token # => 43-character URL-safe string
user_repo.update(user.id, token: reset_token, password_reset_sent_at: Time.now)
```

```ruby
email_subject("SomeApp") # => "SomeApp -- password reset request"
```

Provide the reset url, user's name, link validity, time unit and optionally the
application name when building the body:

```ruby
html_body = email_body_html(
  reset_url: reset_url,
  user_name: "#{user.name} #{user.surname}",
  link_validity: 2,
  time_unit: "hour",
  app_name: nil
)
```

`app_name` falls back to the `APP_NAME` environment variable, then to your Hanami
app's namespace, then to "Application".


**Verifying a reset link**

Use `verify_reset_token`. It takes the token from the params and a block that looks
the user up, and returns the user only if the token is present, a user matches, and
the link is still inside its validity window. Any failure returns nil, so one check
covers every case:

```ruby
def handle(request, response)
  user = verify_reset_token(request.params[:token]) { |t| user_repo.find_by_token(t) }

  unless user
    response.flash[:failed_notice] = "This link is invalid or has expired."
    response.redirect_to "/passwordreset/new"
    return
  end

end
```

The block must return nil when no user matches. With ROM, use `.one` rather than
`.one!` — `.one!` raises on no match and the exception escapes before
`verify_reset_token` can return nil.

Validity defaults to 3600 seconds. Override per call with
`link_validity_seconds:`, or globally with a `custom_link_validity_seconds` method.

`password_reset_url_valid?(link_validity, user)` remains available for direct use
to support backward compatibility, but `verify_reset_token` is preferred because
it performs the checks in the correct order.


**Invalidating the token after a reset — required**

Tachiban does not clear tokens after use. It's best you clear them in
the same update as the new password and you can use the `reset_token_attributes` for that.
Otherwise the token is valid until its window expires and can be reused.

```ruby
user_repo.update(
  user.id,
  hashed_pass: hashed_password(new_password),
  **reset_token_attributes
)
```


## 3. Default values and custom overrides
There are a few default values set which can be overridden in two ways: by passing an argument at the call site,
or by defining a private custom method on your action. See the table below.

Precedence: **explicit argument → custom method → built-in default.**

|Method            |Argument            |Custom method                     |Default                                |
|---               |---                 |---                               |---                                    |
|`login`           |`flash_message:`    |`custom_login_flash_message`      |'You have been successfully logged in.'|
|`login`           |`login_redirect_url:`|`custom_login_redirect_url`      |'/'                                    |
|`logout`          |`logout_redirect_url:`|`custom_logout_redirect_url`    |'/login'                               |
|`session_expired?`|`validity_time:`    |`custom_session_validity_time`    |600                                    |
|`handle_session`  |`redirect_url:`     |`custom_handle_session_redirect_url`|'/'                                  |
|`handle_session`  |—                   |`custom_session_expired_message`  |'Your session has expired.'            |
|`verify_reset_token`|`link_validity_seconds:`|`custom_link_validity_seconds`|3600                               |


**All time values are in seconds.** `validity_time` and `custom_session_validity_time`
are the same value under different names — 600 means ten minutes in both.

Custom methods can be private — Tachiban looks up private methods too, so you don't
need to expose them on your action's public interface.

Define them on your base action to apply everywhere, or on a single action to
override just that one:

```ruby
# app/action.rb — applies to every action
module MyApplication
  class Action < Hanami::Action
    include Hanami::Tachiban

    private

    def custom_session_validity_time
      1800
    end
  end
end

# app/actions/admin/dashboard.rb — tighter window for this action only
module MyApplication
  module Actions
    module Admin
      class Dashboard < MyApplication::Action
        private

        def custom_session_validity_time
          300
        end
      end
    end
  end
end
```




## 4. Changelog

#### 2.1.0
Backward compatible with 2.0.0. All existing method signatures are unchanged.

**Security fixes:**
- `authenticated?` no longer returns early when no user is found. It verifies the
  submitted password against a precomputed dummy hash instead, so existing and
  non-existing accounts take the same time to respond. This closes an account
  enumeration vulnerability where a valid email could be identified
  by a slower response.
- `authenticated?` also handles a user record with a nil `hashed_pass`, and returns
  false for a nil password instead of raising.
- `password_reset_url_valid?` now fails closed. It returns false for a nil user or a
  user with no `password_reset_sent_at`, where it previously raised NoMethodError.
- `session_expired?` now returns true when `session_start_time` is missing, rather
  than raising. An undateable session is treated as expired.
- Reset tokens are now 32 bytes (`SecureRandom.urlsafe_base64(32)`).

**New methods:**
- `verify_reset_token(token, link_validity_seconds: nil)` — performs the
  blank-token check, the user lookup and the expiry check in the correct order and
  returns the user or nil. Recommended over calling `password_reset_url_valid?`
  directly.
- `reset_token_attributes` — returns `{token: nil, password_reset_sent_at: nil}` for
  passing to the repo's update method after a successful reset. **Tachiban does not
  invalidate tokens by itself.** Failing to clear them leaves reset links replayable
  indefinitely.

**New feature — custom method hooks:**
Default values can now be overridden by defining private methods on your action
instead of passing arguments. This makes defaults configurable for `before` callbacks
like `handle_session`, which Hanami calls with a fixed argument list. See section 3.

**Other:**
- Requires for `hanami-controller` and `hanami-action` were dropped.

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

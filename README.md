# Tachiban

[![Join the chat at https://gitter.im/sebastjan-hribar/tachiban](https://badges.gitter.im/sebastjan-hribar/tachiban.svg)](https://gitter.im/sebastjan-hribar/tachiban?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Gem Version](https://badge.fury.io/rb/tachiban.svg)](https://badge.fury.io/rb/tachiban)

Tachiban (立ち番 - standing watch) provides simple authentication system for [Hanami web applications](http://hanamirb.org/) by using bcrypt for password hashing and
offers the following functionalities (with methods listed below
  under Methods by features):
- Signup
- Login
- Authentication
- Session handling

The Tachiban logic and code were extracted from a Hanami based web app using
Hanami::Model and was also used in a Camping based web app using Active Record.


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

#### Prerequisites
The entity for which authentication is used must have the
attribute `hashed_pass` to hold the generated hashed password.

Prior to authenticating or logging in the user, retrieve them from the database and assign them to the instance variable of `@user`.


#### Usage by features

###### Signup
To create a user with a hashed password use the `hashed_password(password)` method for the password and store it as the user's attribute `hashed_pass`.

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

###### Login
To authenticate a user use the `authenticated?(input_password)` method and log them in with the `login` method. Authentication is successful if the user exists and passwords match.

The user is logged in by setting the user object as the `session[:current_user]`. After the user is logged in the session start time is defined as `session[:session_start_time] = Time.now`. A flash message is also assigned as `flash[:success_notice] = flash_message`.

The `session[:session_start_time]` is then used by the `session_expired?` method to determine whether the session has expired or not.

*Example*

```ruby
# Create action for an entity session
email = params[:entity_session][:email]
password = params[:entity_session][:password]

@user = EntityRepository.new.find_by_email(email)
login("You have been successfully logged in.") if authenticated?(password)
```


###### Authentication
To check whether the user is logged in use the `check_for_logged_in_user
` method.


###### Session handling
Tachiban handles session expiration by checking if a session has
expired and then restarts the session start time if the session
is still valid or proceeds with the following if the session
has expired:

- setting the `session[:current_user]` to `nil`
- a flash message is set: `flash[:failed_notice] = "Your session has expired"`
- redirects to the `routes.root_path` which can be overwritten by assigning
a different url to @redirect_url


The `session_expired?` method compares the session start time
increased for the defined `@validity_time` (set to 10 minutes
by default, but can be overwritten) with the current time.

`handle_session` method:
```ruby
  def handle_session
    if session_expired?
      @redirect_url ||= routes.root_path
      session[:current_user] = nil
      flash[:failed_notice] = "Your session has expired"
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


###### Password reset
The password reset feature provides a few simple methods to generate a 
token, email subject and body. It is also possible to specify and 
check the validity of the password reset url.

The token can be used to compose the password reset url. It can be stored 
as the user's attribute and then used to retrieve the correct user from 
the database when the user visits the password reset url.

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

The link validity must me specified in seconds.
```ruby
password_reset_url_valid?(link_validity)
```


### ToDo
~~1. Add support for password reset and update.~~
2. Add support for level based authorizations.

<!-- ## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sebastjan-hribar/tachiban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

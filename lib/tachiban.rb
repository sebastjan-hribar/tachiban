require "tachiban/version"
require 'bcrypt'
require 'hanami/controller'
require 'hanami/action/session'
require 'hanami/model'
require 'fileutils'

module Hanami
  module Tachiban


  # ### Signup methods ###
  # The hashed_password method generates a hashed version of the user's
  # password. By default it includes a salt and the default cost factor
  # of 10 provided by BCrypt. Hashed password should be stored in the database
  # as a user's attribute so it can be retrieved during the login process.

    def hashed_password(password)
      BCrypt::Password.create(password)
    end

  # ### Login methods ###
  # The authenticated? method returns true if the the following criteria
  # are true:
  # - user
  # - user's hashed password from the database matches the input password


    def authenticated?(input_pass)
      @user && BCrypt::Password.new(@user.hashed_pass) == input_pass
    end

  # The login method is to be used in combination with authenticated? method to
  # log the user in if the authenticated? method returns true. The user is
  # logged in by setting the user object as the session[:current_user].
  # Example:
  # login if authenticated?(input_pass)

    def login
      session[:current_user] = @user
    end

  # ### Authentication methods ###
  # The check_for_logged_in_user method can be used to check for each
  # request whether the user is logged in. If user is not loggen in
  # they are redirected to "/".

    def check_for_logged_in_user
      #unless ENV['HANAMI_ENV'] == 'test'
        redirect_to '/' unless session[:current_user]
      #end
    end

  # ### Password reset methods ###
  # The password_reset_sent_at method provides the timestamp of when
  # the password has been sent. This can later be used to define the
  # password reset link expiration time.

    def password_reset_sent_at
      Time.now
    end

  # The token method generates a token to be used for building unique links
  # for password confirmation requests.

    def token
      SecureRandom.urlsafe_base64
    end

  # The email_body method provides basic message of the password reset
  # email. The method accepts the url part of the reset link and the token as
  # arguments.
  #
  # URL example: "http://localhost:2300/passwordupdate/"

    def email_body(url, token)
      "Click the link to reset your password: #{url}#{token}."
    end

  # The email subject method provides the subject for the password reset email
  # and takes the application name as an argument to form the subject.
  #
  # Example: "Some application - password reset link" or "Password reset link"

    def subject(app_name = "")
      name = app_name
      if name == ""
        return "Password reset"
      else
        return "#{name} - password reset link"
      end
    end


    # ### Authorization methods ###
    # The authorized? method checks if the specified user has the required role
    # and permission to access the action. It returns true or false and
    # provides the basis for further actions in either case.
    #
    # Example: redirect_to "/" unless authorized?
    def authorized?
      Object.const_get(@controller_name + "Policy").new(@role, @permissions).send("#{@action_name.downcase}?")
    end

  end
end

::Hanami::Controller.configure do
  prepare do
    include Hanami::Tachiban
  end
end

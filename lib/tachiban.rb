require "tachiban/version"
require 'bcrypt'
require 'hanami/controller'
require 'hanami/action/session'
require 'hanami/model'

module Hanami
  module Tachiban

    #private
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
  # login if authenticated?

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
  end
end

::Hanami::Controller.configure do
  prepare do
    include Hanami::Tachiban
  end
end

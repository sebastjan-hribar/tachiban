require "tachiban/version"
require 'bcrypt'
require 'hanami/controller'
require 'hanami/action/session'
require 'hanami/action'
require 'hanami/model'

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
  # - a user
  # - a user's hashed password from the database matches the input password

    def authenticated?(input_pass)
      @user && BCrypt::Password.new(@user.hashed_pass) == input_pass
    end


  # The login method should be used in combination with the authenticated? method to
  # log the user in if the authenticated? method returns true. The user is
  # logged in by setting the user object as the session[:current_user].
  # After the user is logged in the session start time is defined, which is then used 
  # by the check_session_validity method to determine whether the session has
  # expired.

  # Example:
  # login if authenticated?(input_pass)

    def login(flash_message)
      session[:current_user] = @user
      session[:session_start_time] = Time.now
      flash[:success_notice] = flash_message
    end
  

  # The logout method sets the current user in the session to nil
  # and performs a redirect to the @redirect_to which is set to "/"
  # and can be overwritten as needed with a specific url.

    def logout
      session[:current_user] = nil
      @redirect_url ||= "/"
      redirect_to @redirect_url
    end


  # ### Authentication methods ###

  # The check_for_logged_in_user method can be used to check for each
  # request whether the user is logged in. If user is not logged in
  # the current user in session is set to nil and redirected to "/".

    def check_for_logged_in_user
        logout unless session[:current_user]
    end


  # Session handling

  # If session start time + validity time is greater
  # then the current time, the session expires, the
  # session user is set to nil.
  
  # The @validity_time method can be set and specified in seconds.
  # Example: @validity_time = 300
  # Otherwise the deafult session timeout is set to 600 seconds.

  # The @redirect_to method can be used to set a specific url to redirect to.
  # Otherwise the default redirect url is set to "/".

  
    def check_session_validity
      if session[:current_user]
        @validity_time ||= 600
        @redirect_url ||= "/"
        if session[:session_start_time] + @validity_time.to_i < Time.now
          session[:current_user] = nil
          flash[:failed_notice] = "Your session has expired"
          redirect_to @redirect_url
        else
          session[:session_start_time] = Time.now
        end
      end
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
  # email. The method accepts the url part of the reset url and the token as
  # arguments.
  #
  # URL example: "http://localhost:2300/passwordupdate/"

    def email_body(url, token)
      "Use the url to reset your password: #{url}#{token}."
    end

  # The email subject method provides the subject for the password reset email
  # and takes the application name as an argument to form the subject.
  #
  # Example: "Some application - password reset url" or "Password reset url"

    def subject(app_name = "")
      app_name.empty? ? "Password reset url" : "#{app_name} - password reset url"
    end
  

  end
end

::Hanami::Controller.configure do
  prepare do
    include Hanami::Tachiban
  end
end

require 'tachiban/version'
require 'bcrypt'
require 'hanami/controller'
require 'hanami/action/session'

module Hanami
  module Tachiban

private

  # ### Signup ###

  # The hashed_password method generates a hashed version of the user's
  # password. By default it includes a salt and the default cost factor
  # of 10 provided by BCrypt. Hashed password should be stored in the database
  # as a user's attribute so it can be retrieved during the login process.

    def hashed_password(password)
      BCrypt::Password.create(password)
    end


  # ### Login ###

  # The authenticated? method returns true if the the following criteria
  # are true:
  # - a user exists
  # - a user's hashed password from the database matches the input password

    def authenticated?(input_pass)
      @user && BCrypt::Password.new(@user.hashed_pass) == input_pass
    end


  # The login method can be used in combination with the authenticated? method to
  # log the user in if the authenticated? method returns true. The user is
  # logged in by setting the user object as the session[:current_user].
  # After the user is logged in the session start time is defined, which is then used
  # by the session_expired? method to determine whether the session has
  # expired or not.

  # Example:
  # login if authenticated?(input_pass)

    def login(flash_message)
      session[:current_user] = @user
      session[:session_start_time] = Time.now
      flash[:success_notice] = flash_message
    end


  # The logout method sets the current user in the session to nil
  # and performs a redirect to the @redirect_to which is set to
  # routes.root_path and can be overwritten as needed with a specific url.

    def logout
      session[:current_user] = nil
      @redirect_url ||= routes.root_path
      redirect_to @redirect_url
    end


  # ### Authentication ###

  # The check_for_logged_in_user method can be used to check for each
  # request whether the user is logged in. If the user is not logged in
  # the logout method takes over.

    def check_for_logged_in_user
        logout unless session[:current_user]
    end


  # ### Session handling ###

  # Session handling  includes methods session_expired?,
  # restart_session_counter and handle session.

  # The session_expired? method compares the session start time
  # increased for the defined validity time (set to 10 minutes
  # by default and can be overwritten) with the current time.

    def session_expired?
      if session[:current_user]
        @validity_time ||= 600
        session[:session_start_time] + @validity_time.to_i < Time.now
      end
    end


  # The restart_session_counter method resets the session start time to
  # Time.now. It's used in the handle  session method.

    def restart_session_counter
      session[:session_start_time] = Time.now
    end


    # The handle_session method is used to handle the incoming requests
    # based on the the session expiration. If the session has expired the
    # session user is set to nil, a flash message of "Your session has expired"
    # is provided and a redirect to a default url of routes.root_path
    # is triggered.

    # If the session hasn't expired the restart_session_counter method is
    # called to reset the session start time.

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


  # ### Password reset ###

    def password_reset_sent_at
      Time.now
    end


    def token
      SecureRandom.urlsafe_base64
    end


    def email_subject(app_name)
      "#{app_name} -- password reset request"
    end


    def email_body(url, token, link_validity, time_unit)
      "Visit this url to reset your password: #{url}#{token}. \n
      The url will be valid for #{link_validity} #{time_unit}(s)."
    end

  end
end

::Hanami::Controller.configure do
  prepare do
    include Hanami::Tachiban
  end
end

require 'tachiban/version'
require 'argon2'
require 'securerandom'

module Hanami
  module Tachiban

    # ### Account Enumeration Vulnerability Mitigation ###

    # To close the account enumeration vulnerability via response timing,
    #   a dummy hash is computed once when Tachiban loads. When no user is found,
    #   the provided password is verified against that dummy hash instead of
    #   returning immediately. Both the existing-account and missing-account paths
    #   then perform one Argon2 verification, so the response time no longer tells
    #   an attacker whether an account exists.
    #
    #   The dummy hash is precomputed rather than generated per request on purpose:
    #   Argon2 hash creation is more expensive than verification, so generating one
    #   per miss would make the missing-account path measurably slower and reopen
    #   the leak in the other direction.

    DUMMY_HASH = Argon2::Password.create(SecureRandom.hex(32)).freeze

    private

    # The `tachiban_custom` helper looks up an optional customization method
    #   on the including action. If the action defines `name`, calls it and
    #   returns its result; otherwise returns `fallback`.
    #   The second argument to `respond_to?` includes private methods, so actions
    #   can keep their overrides private.
    #
    #   Custom methods can be used in the base action, a specific action or both.
    #
    #   # app/action.rb
    #   module MyApp
    #     class Action < Hanami::Action
    #       include Hanami::Tachiban
    #
    #       private
    #
    #       def custom_session_validity_time
    #         1800
    #       end
    #
    #       def custom_handle_session_redirect_url
    #         "/login"
    #       end
    #     end
    #   end
    #
    #   # app/actions/admin/dashboard.rb
    #   module MyApp
    #     module Actions
    #       module Admin
    #         class Dashboard < MyApp::Action
    #           private
    #
    #           def custom_session_validity_time
    #             300
    #           end
    #         end
    #       end
    #     end
    #   end
    def tachiban_custom(name, fallback)
      respond_to?(name, true) ? send(name) : fallback
    end


    # ### Signup ###

    # The `hashed_password` method generates a hashed version of the user's
    #   password. Password hashing is provided by Argon2. Hashed password
    #   by default includes a salt and the default cost factor.
    #
    #   Hashed password should be stored in the database as a user's
    #   attribute so it can be retrieved during the login process.
    def hashed_password(password)
      Argon2::Password.create(password)
    end

    # ### Login ###

    # The `authenticated?` method returns true if the following criteria
    #   are true:
    #   - a user exists
    #   - a user's hashed password from the database matches the input password
    #
    #   The Account Enumeration Vulnerability Mitigation is in place.
    def authenticated?(input_pass, user)
      return false if input_pass.nil?

      if user.nil? || user.hashed_pass.nil?
        Argon2::Password.verify_password(input_pass, DUMMY_HASH)
        return false
      end

      Argon2::Password.verify_password(input_pass, user.hashed_pass)

    rescue Argon2::ArgonHashFail
      false
    end

    # The `login` method can be used in combination with the `authenticated?` method to
    #   log the user in if the `authenticated?` method returns true. The user is
    #   logged in by setting the user object id as the `session[:current_user]`.
    #   After the user is logged in the session start time is defined, which is then used
    #   by the `session_expired?` method to determine whether the session has
    #   expired or not.

    #   There are two default values set: one for flash message and
    #   the other for redirect url. Both can be overwritten by using
    #   custom method helper.

    #   Example:
    #   login(request, response, user.id) if authenticated?(input_pass)
    def login(request, response, user_id, flash_message: nil, login_redirect_url: nil)
      request.session[:current_user] = user_id
      request.session[:session_start_time] = Time.now
      response.flash[:success_notice] = flash_message || tachiban_custom(:custom_login_flash_message,
                                        'You have been successfully logged in.')
      response.redirect_to(login_redirect_url || tachiban_custom(:custom_login_redirect_url, '/'))
    end

    # The `logout` method sets the current user in the session to nil
    #   and performs a redirect to the `logout_redirect_url` which is set to
    #   `'/login'`, but can be overwritten as needed with a specific url
    #   by using custom method helper.
    def logout(request, response, logout_redirect_url: nil)
      request.session[:current_user] = nil
      request.session.clear
      response.redirect_to(logout_redirect_url || tachiban_custom(:custom_logout_redirect_url, "/login"))
    end

    # ### Authentication ###

    # The `check_for_logged_in_user` method can be used to check for each
    #   request whether the user is logged in. If the user is not logged in
    #   the logout method takes over.
    def check_for_logged_in_user(request, response)
      logout(request, response) unless request.session[:current_user]
    end

    # ### Session handling ###

    # Session handling includes methods `session_expired?`,
    #   `restart_session_counter` and `handle_session`.
    #
    #   The `session_expired?` method compares the session start time
    #   increased for the defined validity time in seconds with the current time.
    #   The default validity of 600 seconds (10 minutes) can be overwritten by using the
    #   custom method helper.
    def session_expired?(request, validity_time: nil)
      return false unless request.session[:current_user]
      return true unless request.session[:session_start_time]

      validity_time ||= tachiban_custom(:custom_session_validity_time, 600)
      request.session[:session_start_time] + validity_time.to_i < Time.now
    end

    # The `restart_session_counter` method resets the session start time to
    #   `Time.now`. It's used in the `handle_session` method.
    def restart_session_counter(request)
      request.session[:session_start_time] = Time.now
    end

    # The `handle_session` method is used to handle the incoming requests
    #   based on the session expiration. If the session has expired the
    #   session user is set to nil, a flash message of "Your session has expired"
    #   is provided and a redirect to a default url of "/" is triggered.
    #
    #   Both default values can be overwritten by using the custom method helper.
    #
    #   If the session hasn't expired the `restart_session_counter` method is
    #   called to reset the session start time.
    def handle_session(request, response, redirect_url: nil)
      if session_expired?(request)
        redirect_url ||= tachiban_custom(:custom_handle_session_redirect_url, "/")
        request.session[:current_user] = nil
        response.flash[:failed_notice] = tachiban_custom(:custom_session_expired_message,
                                                           'Your session has expired.')
        response.redirect_to redirect_url
      else
        restart_session_counter(request)
      end
    end

    # ### Password reset ###
    # The password reset functionalities include token generation, token invalidation,
    #   email subject, email body in the text as well as in the html format,
    #   checking the reset link validity and getting the app name.
    def token
      SecureRandom.urlsafe_base64(32)
    end

    # After a successful reset the token and the timestamp of the password reset link
    #   must be reset. The attributes are prepared to be passed to the update repo method.
    #
    #   Usage:
    #   user_repo.update(user.id, hashed_pass: hashed_password(new_password), **reset_token_attributes)
    def reset_token_attributes
      {token: nil, password_reset_sent_at: nil}
    end

    def email_subject(app_name)
      app_name ||= default_app_name
      "#{app_name} -- password reset request"
    end

    def email_body_text(reset_url:, user_name:, link_validity:, time_unit:, app_name: nil)
      app_name ||= default_app_name

      <<~TEXT
        Hello #{user_name},

        Click the link below to reset your password:

        #{reset_url}

        This link will expire in #{link_validity} #{time_unit}(s).

        Kind regards,
        The #{app_name} Team
      TEXT
    end

    def email_body_html(reset_url:, user_name:, link_validity:, time_unit:, app_name: nil)
      app_name ||= default_app_name

      <<~HTML
        <!DOCTYPE html>
          <html>
            <body style="font-family: Arial, sans-serif;">
              <h2>Password reset request</h2>
              <br>
              <p>Hello #{user_name},</p>
              <br>
              <p>Click the button below to reset your password:</p>
              <p>
                <a href="#{reset_url}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px;">
                  Reset Password
                </a>
              </p>
              <br>
              <p>Or copy this link: #{reset_url}</p>
              <p style="color: #666; font-size: 12px;">This link expires in #{link_validity} #{time_unit}(s).</p>
            </body>
          </html>
      HTML
    end

    # The `password_reset_url_valid?` method checks whether a user's password
    #   reset link is still within its validity window.
    #   State the link validity in seconds. The method returns false
    #   for a nil user or a user with no reset timestamp, so it fails closed.
    #
    #   This method can still be called directly, but it is advised to use the
    #   `verify_reset_token` method to cover all link and token validity
    #   checks at the same time.
    def password_reset_url_valid?(link_validity, user)
      return false unless user
      return false unless user.password_reset_sent_at

      Time.now < user.password_reset_sent_at + link_validity.to_i
    end

    # Verifies the validity of a password reset token by checking:
    #   - presence of the token,
    #   - finding the matching user if token is present and
    #   - checking the link validity in seconds.
    #
    #   If all checks pass, it returns a valid matching user, otherwise it returns nil.
    #   The token is passed to the block when the method is called.
    #
    #   The block must return nil when no user matches — use ROM's `.one`
    #   rather than `.one!`, since `.one!` raises and the exception would
    #   escape before this method can return nil.
    #
    #   In a handle method it can be used like:
    #
    #   user = verify_reset_token(request.params[:token]) { |t| user_repo.find_by_token(t) }
    def verify_reset_token(token, link_validity_seconds: nil)
      return nil if token.nil? || token.to_s.strip.empty?

      user = yield(token)
      link_validity_seconds ||= tachiban_custom(:custom_link_validity_seconds, 3600)
      password_reset_url_valid?(link_validity_seconds, user) ? user : nil
    end

    def default_app_name
      ENV.fetch("APP_NAME") do
        Hanami.respond_to?(:app) ? Hanami.app.namespace.to_s : "Application"
      end
    rescue StandardError
      "Application"
    end
  end
end
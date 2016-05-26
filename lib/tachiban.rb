require "tachiban/version"
require 'bcrypt'

module Tachiban

# ###Signup methods###
# The generate_salt method generates salt to be used in generating
# hash_secret. Salt should be stored in the database so it can be retrieved
# during the login process.

  def generate_salt
    BCrypt::Engine.generate_salt
  end

# The password_hash method generates hash_secret by using the user's
# password and salt. Password hash should be stored in the database so
# it can be retrieved during the login process.

  def password_hash(password, salt)
    BCrypt::Engine.hash_secret(password, salt)
  end

# ###Login methods###
# The authenticated? method returns true if the the following criteria
# are true:
# - user, passed in the method
# - password hash from the database matches the adhoc generated hash_secret using
# the password the user has typed in and the salt from the databse.

  def authenticated?(user, user_pass_hash, user_salt, input_pass)
    user && user_pass_hash == BCrypt::Engine.hash_secret(input_pass, user_salt)
  end

# The login method is to be used in combination with authenticated? method to
# log the user in if the authenticated? method returns true. The user is
# logged in by setting the user object as the session[:current_user].
# Example:
# login(user) if authenticated?

  def login(user)
    session[:current_user] = user
  end

# ###Authentication methods###
# The check_for_logged_in_user method can be used to check for each
# request whether the user is logged in.

  def check_for_logged_in_user
    #unless ENV['HANAMI_ENV'] == 'test'
      halt 401 unless session[:current_user]
    #end
  end

  # ###Password reset methods###
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

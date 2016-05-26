require "tachiban/version"
require 'bcrypt'

module Tachiban

# Signup methods
  def generate_salt
    BCrypt::Engine.generate_salt
  end

  def password_hash(password, salt)
    BCrypt::Engine.hash_secret(password, salt)
  end

# Login methods
  def authenticated?(user, user_pass_hash, user_salt, input_pass)
    user && user_pass_hash == BCrypt::Engine.hash_secret(input_pass, user_salt)
  end

  def login(user)
    session[:current_user] = user
  end

# Authentication methods
  def check_for_signed_in_user
    unless ENV['HANAMI_ENV'] == 'test'
      halt 401 unless session[:current_user]
    end
  end

# Password reset methods
  def password_reset_sent_at
    Time.now
  end

  def token
    SecureRandom.urlsafe_base64
  end
end

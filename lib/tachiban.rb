require "tachiban/version"
require 'bcrypt'

module Tachiban

  def generate_pass_salt
    BCrypt::Engine.generate_salt
  end
  
  def generate_pass_hash(password, salt)
    BCrypt::Engine.hash_secret(password, salt)
  end
  
  def authenticated?(user_pass_hash, user_salt, input_pass)
    if user_pass_hash == BCrypt::Engine.hash_secret(input_pass, user_salt)
      true
    else
      false
    end
  end
  
  def password_reset_sent_at
    Time.now
  end
  
  def token
    SecureRandom.urlsafe_base64
  end
  
end
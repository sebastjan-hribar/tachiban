require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

require_relative "../lib/tachiban"
include Tachiban

describe "Registration" do
  
  it 'generates password salt' do
    generate_pass_salt.must_be_kind_of String
  end
  
  it 'generates password hash' do
    salt = generate_pass_salt
    generate_pass_hash("pass123", salt).must_be_kind_of String
  end
end

describe "Authentication" do
  
  before do
    @existing_user_salt = generate_pass_salt
    @existing_user_password_hash = generate_pass_hash("123", @existing_user_salt)
  end
  
  it "successful authentication" do
    assert authenticated?(@existing_user_password_hash, @existing_user_salt, "123") == true, "User is authenticated"
  end
  
  it "unsuccessful authentication" do
    assert authenticated?(@existing_user_password_hash, @existing_user_salt, "1231") == false, "User is not authenticated"
  end

end

describe "Password reset preparation" do
  
  it "sets the time of password reset" do
    password_reset_sent_at.must_be_kind_of Time  
  end

  it "generates unique token" do
    token.length > 20
  end

end
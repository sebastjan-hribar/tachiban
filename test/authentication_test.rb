require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

require_relative "../lib/tachiban"
include Hanami::Tachiban

class User
  include Hanami::Entity
  attributes :id, :name, :hashed_pass
end

class Login
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    @user = User.new(id: 1, name: "Tester",
    hashed_pass: hashed_password("pass123"))
    login(@user)
  end
end

class AuthTest
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    check_for_logged_in_user
    @user = User.new(id: 1, name: "Tester",
    hashed_pass: hashed_password("pass123"))
    login(@user)
  end
end

describe "Signup" do

  it 'generates hashed password' do
    password = hashed_password("pass123")
    password.must_be_kind_of String
  end
end

describe "Login" do

  before do
    @user = User.new(id: 1, name: "Tester",
    hashed_pass: hashed_password("123"))
  end

  it "successful authentication" do
    assert authenticated?(@user, @user.hashed_pass, "123") == true, "User is authenticated"
  end

  it "unsuccessful authentication" do
    assert authenticated?(@user, @user.hashed_pass, "1231") == false, "User is not authenticated"
  end

  it "logs the user in" do
    action = Login.new
    action.call({})
    action.session[:current_user].name.must_equal "Tester"
  end

 end

describe "Authentication" do

  it 'wont let unauthenticated user pass' do
    action = AuthTest.new
    action.call({})
    action.session[:current_user].must_be_nil
  end

end

describe "Password reset" do

  it "sets the time of password reset" do
    password_reset_sent_at.must_be_kind_of Time
  end

  it "generates unique token" do
    token.length > 20
  end

end

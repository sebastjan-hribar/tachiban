require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'
require 'hanami/controller'
require 'hanami/action/session'
require 'hanami/model'

require_relative "../lib/tachiban"
include Tachiban


describe "Signup" do

  it 'generates salt' do
    generate_salt.must_be_kind_of String
  end

  it 'generates password hash' do
    salt = generate_salt
    password_hash("pass123", salt).must_be_kind_of String
  end
end

describe "Login" do
  class Login
    include Hanami::Action
    include Hanami::Action::Session

    def call(params)
      @test_user = User.new(id: 1, name: "Tester",
    pass_hash: @existing_user_password_hash, pass_salt: @existing_user_salt)
      login(@test_user)
    end
  end

  class User
    include Hanami::Entity
    attributes :id, :name, :pass_hash, :pass_salt
  end

  before do
    @existing_user_salt = generate_salt
    @existing_user_password_hash = password_hash("123", @existing_user_salt)
    @test_user = User.new(id: 1, name: "Tester",
    pass_hash: @existing_user_password_hash, pass_salt: @existing_user_salt)
  end


  it "successful authentication" do
    assert authenticated?(@test_user, @test_user.pass_hash, @test_user.pass_salt, "123") == true, "User is authenticated"
  end

  it "unsuccessful authentication" do
    assert authenticated?(@test_user, @test_user.pass_hash, @test_user.pass_salt, "1231") == false, "User is not authenticated"
  end

  it "logs the user in" do
    action = Login.new
    action.call({})
    action.session[:current_user].name.must_equal "Tester"
  end

 end

describe "Authentication" do
  #Write test for authentication
end

describe "Password reset" do

  it "sets the time of password reset" do
    password_reset_sent_at.must_be_kind_of Time
  end

  it "generates unique token" do
    token.length > 20
  end

end

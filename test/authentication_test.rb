require 'test_helper'

class User
  include Hanami::Entity
  attributes :id, :name, :hashed_pass
end

class Login
  include Hanami::Action
  include Hanami::Action::Session


  def call(params)
    @user = params[:user]
    login
  end
end

describe "Login" do

  before do
    @action = Login.new
  end

  describe "with user" do

    before do
      user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
      @action.call({ user: user })
    end

    it "successful authentication" do
      assert @action.authenticated?("123") == true, "User is authenticated"
    end

    it "unsuccessful authentication" do
      assert @action.authenticated?("1231") == false, "User is not authenticated"
    end

    it "saves the user to the session" do
      @action.session[:current_user].name.must_equal "Tester"
    end

  end

  describe "without user" do
    before { @action.call({}) }

    it 'session wont have user' do
      @action.session[:current_user].must_be_nil
    end
  end

end

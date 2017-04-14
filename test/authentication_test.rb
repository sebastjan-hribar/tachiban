require 'test_helper'

class User < Hanami::Entity
  attributes do
    attribute :id,           Types::Int
    attribute :name,         Types::String
    attribute :hashed_pass,   Types::String
  end
end

class Login
  include Hanami::Action
  include Hanami::Action::Session


  def call(params)
    @user = params[:user]
    login("You were successfully logged in.")
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
      assert @action.send(:authenticated?, "123") == true, "User is authenticated"
    end

    it "unsuccessful authentication" do
      assert @action.send(:authenticated?, "1231") == false, "User is not authenticated"
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


describe "Session validity" do
  before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
      @action = Login.new
      @action.call({ user: @user })
    end

  describe "with a valid new request" do

    it 'a new request comes in on time' do
      Timecop.travel(Time.now + 200) do
        @action.instance_variable_set(:@validity_time, 500)
        @action.send(:session_expired?).must_equal false
      end
    end

  end


  describe "with an invalid new request" do

    it 'a new request comes in too late' do
      Timecop.travel(Time.now + 800) do
        @action.instance_variable_set(:@validity_time, 5)
        @action.send(:session_expired?).must_equal true
      end
    end

  end

end

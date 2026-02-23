require 'test_helper'

describe "Login" do
  before do
    @action = TestAction.new
  end

  describe "with user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
      #@action.instance_variable_set(:@user, user)
    end

    it "successful authentication" do
      result = @action.send(:authenticated?, "123", @user)
      value(result).must_equal true
    end

    it "has a successful flash notice after successful login" do
      @action.send(:authenticated?, "123", @user)
      @action.send(:login, @action.request, @action.response, @user.id)

      flash = @action.response.flash[:success_notice]
      value(flash).must_equal "You have been successfully logged in."
    end

    it "unsuccessful authentication" do
      result = @action.send(:authenticated?, "1231", @user)
      value(result).must_equal false
    end

    it "saves the user to the session" do
      @action.send(:login, @action.request, @action.response, @user.id)
      value(@action.request.session[:current_user]).must_equal 1
    end
  end

  describe "without user" do
    it 'session wont have user' do
      value(@action.request.session[:current_user]).must_be_nil
    end
  end
end

describe "Session validity" do
  before do
      @action = TestAction.new
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
      #@action.instance_variable_set(:@user, user)
      @action.send(:login, @action.request, @action.response, @user.id)
    end

  describe "with a valid new request" do
    it 'a new request comes in on time' do
      Timecop.travel(Time.now + 200) do
        @action.instance_variable_set(:@validity_time, 500)
        value(@action.send(:session_expired?, @action.request)).must_equal false
      end
    end
  end

  describe "with an invalid new request" do
    it 'a new request comes in too late' do
      Timecop.travel(Time.now + 800) do
        @action.instance_variable_set(:@validity_time, 5)
        value(@action.send(:session_expired?, @action.request)).must_equal true
      end
    end
  end
end

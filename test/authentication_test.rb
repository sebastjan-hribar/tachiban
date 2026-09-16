require 'test_helper'

describe "Login" do
  before do
    @action = TestAction.new
  end

  describe "with user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
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

    it "returns false for a nil user" do
      value(@action.send(:authenticated?, "123", nil)).must_equal false
    end

    it "returns false for a user with no stored hashed password" do
      hashless_user = User.new(id: 2, name: "Tester", hashed_pass: nil)
      value(@action.send(:authenticated?, "123", hashless_user)).must_equal false
    end

    it "returns false for a nil password" do
      value(@action.send(:authenticated?, nil, @user)).must_equal false
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
      @action.send(:login, @action.request, @action.response, @user.id)
    end

  describe "with a valid new request" do
    it 'a new request comes in on time' do
      Timecop.travel(Time.now + 800) do
        value(@action.send(:session_expired?, @action.request, validity_time: 1000)).must_equal false
      end
    end
  end

  describe "with an invalid new request" do
    it 'a new request comes in too late' do
      Timecop.travel(Time.now + 200) do
        value(@action.send(:session_expired?, @action.request, validity_time: 100)).must_equal true
      end
    end
  end

  describe "custom method hooks" do
    before do
      @action = TestActionWithCustoms.new
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
      @action.send(:login, @action.request, @action.response, @user.id)
    end

    it "uses the custom validity over the default" do
      Timecop.travel(Time.now + 200) do
        value(@action.send(:session_expired?, @action.request)).must_equal true
      end
    end

    it "uses the custom redirect url on expiry" do
      Timecop.travel(Time.now + 200) do
        @action.send(:handle_session, @action.request, @action.response)
        value(@action.response.redirect_url).must_equal "/custom-login"
      end
    end
  end
end

describe 'Logout' do
  before do
    @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"))
    @action = TestAction.new
  end
  
  it "clears the session and redirects" do
    @action.send(:login, @action.request, @action.response, @user.id)
    @action.send(:logout, @action.request, @action.response)
    value(@action.request.session[:current_user]).must_be_nil
    value(@action.response.redirect_url).must_equal "/login"
  end
end

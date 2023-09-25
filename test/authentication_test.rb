require 'test_helper'

describe "Login" do
  before do
    @action = Login.new
  end

  describe "with user" do
    before do
      user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123", "argon2"))
      @action.call({ user: user })
    end

    it "successful authentication" do
      assert @action.send(:authenticated?, "123", "bcrypt") == true, "User is authenticated."
      flash = @action.exposures[:flash][:success_notice]
      value(flash).must_equal "You have been successfully logged in."
    end

    it "unsuccessful authentication" do
      assert @action.send(:authenticated?, "1231", "bcrypt") == false, "User is not authenticated"
    end

    it "saves the user to the session" do
      value(@action.session[:current_user]).must_equal 1
    end
  end

  describe "without user" do
    before { @action.call({}) }

    it 'session wont have user' do
      value(@action.session[:current_user]).must_be_nil
    end
  end
end

describe "Session validity" do
  before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123", "argon2"))
      @action = Login.new
      @action.call({ user: @user })
    end

  describe "with a valid new request" do
    it 'a new request comes in on time' do
      Timecop.travel(Time.now + 200) do
        @action.instance_variable_set(:@validity_time, 500)
        value(@action.send(:session_expired?)).must_equal false
      end
    end
  end

  describe "with an invalid new request" do
    it 'a new request comes in too late' do
      Timecop.travel(Time.now + 800) do
        @action.instance_variable_set(:@validity_time, 5)
        value(@action.send(:session_expired?)).must_equal true
      end
    end
  end
end

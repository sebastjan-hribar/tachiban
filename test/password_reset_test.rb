require 'test_helper'

describe 'Hanami::Tachiban' do
  describe 'Password reset' do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"), password_reset_sent_at: Time.now)
    end

    it "generates token for password reset url" do
      assert token.length > 20
      value(token).must_be_kind_of String
    end

    it "provides a subject with the app name" do
      email_subject = email_subject("My app")
      value(email_subject).must_equal("My app -- password reset request")
    end

    it "provides a default basic password reset body text" do
      #email_body_text(reset_url:, user_name:, link_validity:, time_unit:, app_name: nil)
      body = email_body_text(reset_url: "http://localhost:2300/passwordupdate/", user_name: @user.name,
                               link_validity: 2, time_unit: "hour", app_name: "The Great App")
      assert body.include?("Click the link below to reset your password:")
      assert body.include?("This link will expire in 2 hour(s).")
      assert body.include?("Tester")
    end

    it "asserts that password update url is not valid" do
      Timecop.travel(Time.now + 7400) do
        assert_equal false, password_reset_url_valid?(7200, @user)
      end
    end

    it "asserts that password reset url is valid" do
      Timecop.travel(Time.now + 7400) do
        assert_equal true, password_reset_url_valid?(7600, @user)
      end
    end
  end
end

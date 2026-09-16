require 'test_helper'

describe 'Hanami::Tachiban' do
  describe 'Password reset' do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"), password_reset_sent_at: Time.now)
    end

    describe 'Token generation and validation' do
      it "generates token for password reset url" do
        value(token.length).must_equal 43 
        value(token).must_be_kind_of String
      end

      it "returns nil for a nil token" do
        value(verify_reset_token(nil) { |t| @user }).must_be_nil
      end

      it "returns nil for a blank token" do
        value(verify_reset_token("   ") { |t| @user }).must_be_nil
      end

      it "returns nil when no user matches" do
        value(verify_reset_token("abc") { |t| nil }).must_be_nil
      end

      it "returns the user for a valid token" do
        value(verify_reset_token("abc") { |t| @user }).must_equal @user
      end

      it "returns nil when the link has expired" do
        Timecop.travel(Time.now + 7400) do
          value(verify_reset_token("abc") { |t| @user }).must_be_nil
        end
      end
    end

    describe 'Password reset email and link validation' do
      it "provides a subject with the app name" do
        subject = email_subject("My app")
        value(subject).must_equal("My app -- password reset request")
      end

      it "provides a default basic password reset body text" do
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

      it "returns false for a nil user" do
        value(password_reset_url_valid?(3600, nil)).must_equal false
      end

      it "returns false when no reset was sent" do
        never_reset = User.new(id: 3, name: "Tester", password_reset_sent_at: nil)
        value(password_reset_url_valid?(3600, never_reset)).must_equal false
      end
    end
  end
end

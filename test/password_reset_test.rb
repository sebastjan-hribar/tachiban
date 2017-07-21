require 'test_helper'
include Hanami::Tachiban



describe 'Hanami::Tachiban' do

  describe 'Password reset' do

    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"), password_reset_sent_at: Time.now)
    end


    it "generates token for password reset url" do
      assert token.length > 20
      token.must_be_kind_of String
    end

    it "provides a subject with the app name" do
      email_subject = email_subject("My app")
      email_subject.must_equal("My app -- password reset request")
    end

    it "provides a default basic password reset body text" do
      body = email_body("http://localhost:2300/passwordupdate/", "asdasdasdaerwrw", 2, "hour")
      body.must_equal("Visit this url to reset your password: http://localhost:2300/passwordupdate/asdasdasdaerwrw. \n
      The url will be valid for 2 hour(s).")
    end

    it "checks the validity of the password reset url" do
      Timecop.travel(Time.now + 7400) do
        assert_equal true, password_reset_url_valid?(7200)
      end
    end
    
    it "checks that password reset url is not valid" do
      Timecop.travel(Time.now + 700) do
        assert_equal false, password_reset_url_valid?(7200)
      end
    end

  end

end

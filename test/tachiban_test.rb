require 'test_helper'
include Hanami::Tachiban

describe 'Hanami::Tachiban' do

  describe 'Generate hashed password' do

    it 'can generate password' do
      password = hashed_password("pass123")
      password.must_be_kind_of String
    end

  end
  
  describe 'Password reset' do

    it "password_reset_sent_at is of type Time" do
      password_reset_sent_at.must_be_kind_of Time
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


  end

end

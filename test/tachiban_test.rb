require 'test_helper'
include Hanami::Tachiban

describe 'Hanami::Tachiban' do

  it 'can generate password' do
    password = hashed_password("pass123")
    password.must_be_kind_of String
  end

  it "password_reset_sent_at is of type Time" do
    password_reset_sent_at.must_be_kind_of Time
  end

  it "generates unique token" do
    token.length > 20
  end

  it "provides a default basic password reset body text" do
    body = email_body("http://localhost:2300/passwordupdate/", "asdasdasdaerwrw")
    body.must_include("Visit the link to reset your password")
    body.must_include("http://localhost:2300/passwordupdate/asdasdasdaerwrw")
  end

  it "provides a subject with the app name" do
    email_subject = subject("My app")
    email_subject.must_include("My app")
  end

  it "provides a subject without the app name" do
    email_subject = subject
    email_subject.must_equal("Password reset url")
  end

end

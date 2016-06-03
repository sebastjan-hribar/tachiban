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

end

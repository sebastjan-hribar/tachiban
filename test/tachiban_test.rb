require 'test_helper'
include Hanami::Tachiban

describe 'Hanami::Tachiban' do

  it 'can generate password' do
    password = hashed_password("pass123")
    password.must_be_kind_of String
  end

end

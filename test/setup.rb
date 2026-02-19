class User
  attr_accessor :id, :name, :hashed_pass, :password_reset_sent_at, :role
  
  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @hashed_pass = attributes[:hashed_pass]
    @password_reset_sent_at = attributes[:password_reset_sent_at]
    @roles = attributes[:roles]
  end
end

class TestRequest
  attr_accessor :params, :session

  def initialize
    @params = {}
    @session = {}
  end
end

class TestResponse
  attr_accessor :flash, :redirect_url

  def initialize
    @flash = {}
    @redirect_url = nil
  end

  def redirect_to(url)
    @redirect_url = url
  end
end

class TestAction
  include Hanami::Tachiban

  attr_reader :request, :response

  def initialize
    @request = TestRequest.new
    @response = TestResponse.new
  end
end
class User < Hanami::Entity
  attributes do
    attribute :id,                      Types::Int
    attribute :name,                    Types::String
    attribute :hashed_pass,             Types::String
    attribute :password_reset_sent_at,  Types::Time
    attribute :permissions,             Types::Array
    attribute :role,                    Types::String
  end
end

class Login
  include Hanami::Action
  include Hanami::Action::Session


  def call(params)
    @user = params.env[:user]
    login("You were successfully logged in.")
  end
end

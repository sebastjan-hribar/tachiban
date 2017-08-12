require 'test_helper'
require_relative 'testApp/lib/policies/firstApp/TaskPolicy.rb'
require_relative '../lib/tachiban/policy_generator/policy_generator.rb'
#include Tachiban::PolicyGenerator


module Web
  module Controllers
    class Task
      class New
        include Hanami::Action
        def controller_name
          self.class.name
        end
      end
    end
  end
end


describe "Authorization" do

  before do
    @action = Web::Controllers::Task::New.new
    @controller_name = @action.controller_name.split("::")[2]
    @action_name = @action.controller_name.split("::")[3]
  end

  describe "with authorized user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"),
      role: "level_one_user")
      @role = @user.role
    end

    after do
      @user = nil
    end

    it "authorizes the user" do
      assert authorized? == true, "User is authorized"
    end
  end


  describe "with unauthorized user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"), role: "guest_user")
    end

    after do
      @user = nil
    end

    it 'doesnt authorize the user' do
      refute authorized?, "User is not authorized"
    end
  end

end

require 'test_helper'

class User
  include Hanami::Entity
  attributes :id, :name, :hashed_pass, :permissions, :role
end

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
      permissions: [1,2,3], role: "normal_user")
      generate_policy("task")
      require_relative '../TaskPolicy.rb'
      @role = @user.role
      @permissions = @user.permissions
    end

    after do
      @user = nil
      File.delete("TaskPolicy.rb")
    end

    it "authorizes the user" do
      assert File.file?("TaskPolicy.rb") == true, "The policy is created."
      assert File.foreach("TaskPolicy.rb").grep(/permissions/).any? == true, "The policy has permission for 'new'."
      assert authorized? == true, "User is authorized"
    end

  end


  describe "with unauthorized user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"),
      permissions: [1,2,3], role: "normal_user")

      generate_policy("task")
      require_relative '../TaskPolicy.rb'
    end

    after do
      @user = nil
      File.delete("TaskPolicy.rb")
    end

    it 'doesnt authorize the user' do
      assert File.file?("TaskPolicy.rb") == true, "The policy is created."
      assert File.foreach("TaskPolicy.rb").grep(/permissions/).any? == true, "The policy has permission for 'new'."
      refute authorized?, "User is not authorized"
    end
  end

end

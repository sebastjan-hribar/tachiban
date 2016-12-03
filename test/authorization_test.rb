require 'test_helper'

class User
  include Hanami::Entity
  attributes :id, :name, :hashed_pass, :permissions, :role
end

describe "Authorization" do

  describe "with authorized user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"),
      permissions: [1,2,3], role: "normal_user")

      generate_policy("task")
    end

    after do
      @user = nil
      File.delete("TaskPolicy.rb")
    end

    it "authorizes the user" do
      assert File.file?("TaskPolicy.rb") == true, "The policy is created."
      assert File.readlines("TaskPolicy.rb").grep("@role == 'user_role' && @permissions.include('1')") == true, "Policy has new permisson."
      assert authorized?(@user.role, [1]) == true, "User is authorized"
    end

  end

  describe "with unauthorized user" do
    before do
      @user = User.new(id: 1, name: "Tester", hashed_pass: hashed_password("123"),
      permissions: [1,2,3], role: "normal_user")

      generate_policy("task")
    end

    after do
      @user = nil
      File.delete("TaskPolicy.rb")
    end

    it 'doesnt authorize the user' do
      assert File.file?("TaskPolicy.rb") == true, "The policy is created."
      assert authorized?(@user.role, []) == false, "User is not authorized"
    end
  end

end

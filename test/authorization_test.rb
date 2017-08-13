require 'test_helper'
require_relative 'testApp/lib/firstApp/policies/TaskPolicy.rb'
require_relative '../lib/tachiban/policy_generator/policy_generator.rb'



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
    @application_name = "firstApp"
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
      assert authorized?(@controller_name, @role, @action_name) == true, "User is authorized"
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
      refute authorized?(@controller_name, @role, @action_name) == true, "User is not authorized"
    end
  end


  describe "policy file creation" do
    before do
      @new_controller = "Post"
    end

    after do
      Dir.chdir('test/testApp') do
        File.delete("lib/#{@application_name}/policies/#{@new_controller}Policy.rb")
      end
    end


    it "generates policy" do
      Dir.chdir('test/testApp') do
        generate_policy(@application_name, @new_controller)
        generated_policy_string = "lib/#{@application_name}/policies/#{@new_controller}Policy.rb"
        assert File.file?("lib/#{@application_name}/policies/#{@new_controller}Policy.rb"), "The file lib/#{@application_name}/policies/#{@new_controller}Policy.rb is generated"
        assert File.readlines(generated_policy_string).grep(/authorized_roles_for_new/).size > 0, "The file has content authorized_roles_for_new."
      end

    end
  end


end

require 'test_helper'


describe "Policy Generator" do

  after do
    File.delete("lib/policies/TaskPolicy.rb")
  end


it "creates the policy" do
  generate_policy("task")
  assert File.file?("lib/policies/TaskPolicy.rb") == true, "The policy is created."
  assert File.foreach("lib/policies/TaskPolicy.rb").grep(/permissions/).any? \
  == true, "The policy has permission for 'new'."
end

end

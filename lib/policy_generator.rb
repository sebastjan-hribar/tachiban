require 'fileutils'

# The generate_policy method creates the policy file for specified
# controller. By default all actions to check against are commented out.
# Uncomment the needed actions and define appropriate user role.
#
# The file is created only if it doesn't exist already.

def generate_policy(controller_name)
  controller = controller_name.downcase.capitalize
  policy_txt = <<-TXT
    class #{controller}Policy
      attr_reader :role, :permissions
      def initialize(role, permissions)
        @role = role
        @permissions = permissions
      end
      # Uncomment the required actions and set the
      # appropriate user role.
      def new?
        @role == 'user_role' && @permissions.include?(1)
      end
      #def create?
      #  @role == 'user_role' && @permissions.include?(2)
      #end
      #def show?
      #  @role == 'user_role' && @permissions.include?(3)
      #end
      #def index?
      #  @role == 'user_role' && @permissions.include?(4)
      #end
      #def edit?
      #  @role == 'user_role' && @permissions.include?(5)
      #end
      #def update?
      #  @role == 'user_role' && @permissions.include?(6)
      #end
      #def destroy?
      #  @role == 'user_role' && @permissions.include?(7)
      #end
    end
    TXT

  FileUtils.mkdir_p 'lib/policies/' unless File.directory?('lib/policies')
  unless File.file?("lib/policies/#{controller}Policy.rb")
    File.open("lib/policies/#{controller}Policy.rb", 'w') { |file| file.write(policy_txt) }
  end
end

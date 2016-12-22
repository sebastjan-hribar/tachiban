    class SomethingPolicy
      attr_reader :role, :permissions

      def initialize(role, permissions)
        @role = role
        @permissions = permissions
      end

      # Uncomment the required actions and set the
      # appropriate user role.

      def new?
        @role == 'normal_user' && @permissions.include?(1)
      end

      #def create?
      #  @role == 'user_role' && @permissions.include?("2")
      #end

      #def show?
      #  @role == 'user_role' && @permissions.include?("3")
      #end

      #def index?
      #  @role == 'user_role' && @permissions.include?("4")
      #end

      #def edit?
      #  @role == 'user_role' && @permissions.include?("5")
      #end

      #def update?
      #  @role == 'user_role' && @permissions.include?("6")
      #end

      #def destroy?
      #  @role == 'user_role' && @permissions.include?("7")
      #end
    end


class TaskPolicy
  attr_reader :role, :permissions
  def initialize(role, permissions)
    @requesting_role = role
    @requesting_permissions = permissions
  end
  # Uncomment the required actions and set the
  # appropriate user role.
  def new?
    @requesting_role == 'level_one_user' && @requesting_permissions.include?(1)
  end
  #def create?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(2)
  #end
  #def show?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(3)
  #end
  #def index?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(4)
  #end
  #def edit?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(5)
  #end
  #def update?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(6)
  #end
  #def destroy?
  #  @requesting_role == 'user_role' && @requesting_permissions.include?(7)
  #end
end

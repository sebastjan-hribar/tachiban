class TaskPolicy

  def initialize(role)
    @user_role = role
    
    # Uncomment the required roles and add the
    # appropriate user role to the @authorized_roles* array.
  
    @authorized_roles_for_new = ["level_one_user"]
    # @authorized_roles_for_create = []
    # @authorized_roles_for_show = []
    # @authorized_roles_for_index = []
    # @authorized_roles_for_edit = []
    # @authorized_roles_for_update = []
    # @authorized_roles_for_destroy = []
  end

  def new?
    @authorized_roles_for_new.include? @user_role
  end
  def create?
    @authorized_roles_for_create.include? @user_role
  end
  def show?
    @authorized_roles_for_show.include? @user_role
  end
  def index?
    @authorized_roles_for_index.include? @user_role
  end
  def edit?
    @authorized_roles_for_edit.include? @user_role
  end
  def update?
    @authorized_roles_for_update.include? @user_role
  end
  def destroy?
    @authorized_roles_for_destroy.include? @user_role
  end
end

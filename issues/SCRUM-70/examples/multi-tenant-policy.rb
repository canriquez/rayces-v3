# Multi-tenant Pundit Policy Example
# This example shows how to implement tenant-aware authorization policies

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.exists?(record.id)
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  protected

  # Multi-tenant helper methods
  def same_organization?
    user.organization_id == record.organization_id
  end

  def user_admin?
    user.enhanced_admin?
  end

  def user_professional?
    user.enhanced_professional?
  end

  def user_secretary?
    user.enhanced_secretary?
  end

  def user_client?
    user.enhanced_client?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" unless user
      @user = user
      @scope = scope
    end

    def resolve
      # Ensure all queries are scoped to the user's organization
      if scope.respond_to?(:where)
        scope.where(organization_id: user.organization_id)
      else
        scope.all
      end
    end
  end
end

# Example Organization Policy with multi-tenant awareness
class OrganizationPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can see organizations
  end
  
  def show?
    # Users can only see their own organization
    user.organization_id == record.id || user_admin?
  end
  
  def create?
    # Only system admins can create organizations (not tenant admins)
    user.system_admin?
  end
  
  def update?
    # Only admins of the same organization can update
    user_admin? && same_organization?
  end
  
  def destroy?
    false # Organizations cannot be destroyed
  end
  
  class Scope < Scope
    def resolve
      # Users can only see their own organization
      scope.where(id: user.organization_id)
    end
  end
end

# Example User Policy with role-based permissions
class UserPolicy < ApplicationPolicy
  def index?
    # All authenticated users can see users in their org
    true
  end

  def show?
    # Users can see others in same organization
    same_organization?
  end

  def create?
    # Admins and secretaries can create users
    (user_admin? || user_secretary?) && same_organization?
  end

  def update?
    # Users can update their own profile
    # Admins can update anyone in their org
    # Secretaries can update clients
    return true if user.id == record.id
    return true if user_admin? && same_organization?
    return true if user_secretary? && same_organization? && record.enhanced_client?
    false
  end

  def destroy?
    # Only admins can delete users in their org
    user_admin? && same_organization? && user.id != record.id
  end

  class Scope < Scope
    def resolve
      # Scope to organization
      scope.where(organization_id: user.organization_id)
    end
  end
end

# Example Appointment Policy with complex role logic
class AppointmentPolicy < ApplicationPolicy
  def index?
    true # All users can see appointments (filtered by scope)
  end

  def show?
    # Users can see appointments based on role
    return true if user_admin? && same_organization?
    return true if user_professional? && assigned_professional?
    return true if user_secretary? && same_organization?
    return true if user_client? && (client_appointment? || family_appointment?)
    false
  end

  def create?
    # Admins, secretaries, and clients can create appointments
    (user_admin? || user_secretary? || user_client?) && same_organization?
  end

  def update?
    # Complex update rules based on state and role
    return false unless same_organization?
    
    case record.state
    when 'draft'
      user_admin? || user_secretary? || (user_client? && client_appointment?)
    when 'pre_confirmed'
      user_admin? || user_secretary?
    when 'confirmed'
      user_admin? || user_secretary? || user_professional?
    when 'executed'
      user_admin? # Only admins can modify executed appointments
    when 'cancelled'
      false # No one can modify cancelled appointments
    else
      false
    end
  end

  def pre_confirm?
    update? && record.draft?
  end

  def confirm?
    (user_admin? || user_secretary?) && record.pre_confirmed? && same_organization?
  end

  def execute?
    (user_admin? || assigned_professional?) && record.confirmed? && same_organization?
  end

  def cancel?
    return false unless same_organization?
    return false if record.executed? || record.cancelled?
    
    user_admin? || user_secretary? || 
      (user_client? && client_appointment? && record.cancellable_by_client?)
  end

  private

  def assigned_professional?
    user_professional? && record.professional_id == user.professional_profile&.id
  end

  def client_appointment?
    record.client_id == user.id
  end

  def family_appointment?
    # Check if appointment is for a family member
    user.family_member_ids.include?(record.student_id)
  end

  class Scope < Scope
    def resolve
      # Complex scoping based on role
      base_scope = scope.where(organization_id: user.organization_id)
      
      if user.enhanced_admin? || user.enhanced_secretary?
        # Admins and secretaries see all appointments in org
        base_scope
      elsif user.enhanced_professional?
        # Professionals see their assigned appointments
        base_scope.where(professional_id: user.professional_profile&.id)
      elsif user.enhanced_client?
        # Clients see their own and family appointments
        student_ids = [user.id] + user.family_member_ids
        base_scope.where(student_id: student_ids)
      else
        base_scope.none
      end
    end
  end
end
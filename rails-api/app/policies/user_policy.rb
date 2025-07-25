# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    # Only admins and staff can list users in their organization
    # Professionals and parents cannot access the full user list
    admin? || staff?
  end
  
  def show?
    # Users can see their own profile
    # Admins and staff can see all users in their organization
    same_tenant? && (owns_record? || admin? || staff?)
  end
  
  def create?
    # Admins and staff can create new users
    admin? || staff?
  end
  
  def update?
    # Users can update their own profile
    # Admins can update any user in their organization
    # Staff can update guardian users only
    return false unless same_tenant?
    
    owns_record? || admin? || (staff? && record.guardian?)
  end
  
  def destroy?
    # Only admins can delete users
    # Users cannot delete themselves
    same_tenant? && admin? && !owns_record?
  end
  
  def manage_role?
    # Only admins can change user roles
    admin? && same_tenant?
  end
  
  class Scope < Scope
    def resolve
      # Temporarily simplified to isolate 500 error
      if user.admin? || user.staff?
        # Admins and staff can see all users in their organization
        scope.where(organization_id: organization&.id)
      else
        # Others can only see themselves
        scope.where(id: user.id)
      end
    end
  end
  
  private
  
  def owner?
    record.id == user.id
  end
end
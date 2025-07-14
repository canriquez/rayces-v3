# app/policies/organization_policy.rb
class OrganizationPolicy < ApplicationPolicy
  def index?
    # Only super admins can list all organizations (future feature)
    false
  end
  
  def show?
    # Users can see their own organization
    record.id == organization.id
  end
  
  def create?
    # Only super admins can create organizations (future feature)
    false
  end
  
  def update?
    # Only admins can update their organization
    admin? && record.id == organization.id
  end
  
  def destroy?
    # Organizations cannot be destroyed through the API
    false
  end
  
  def manage_settings?
    # Only admins can manage organization settings
    admin? && record.id == organization.id
  end
  
  class Scope < Scope
    def resolve
      # Users can only see their own organization
      scope.where(id: organization.id)
    end
  end
end
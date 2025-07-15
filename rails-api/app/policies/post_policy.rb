# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view posts in their organization
  end
  
  def show?
    same_tenant? # Posts must be in same organization
  end
  
  def create?
    true # All authenticated users can create posts
  end
  
  def update?
    owns_record? || admin? # Only post owner or admin can update
  end
  
  def destroy?
    owns_record? || admin? # Only post owner or admin can delete
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Always scope to organization for proper authorization testing
      scope.joins(:user).where(users: { organization_id: organization.id })
    end
  end
end
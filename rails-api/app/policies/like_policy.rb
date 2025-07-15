# app/policies/like_policy.rb
class LikePolicy < ApplicationPolicy
  def show?
    same_tenant? # Likes must be in same organization
  end
  
  def create?
    # Users can only like posts in their organization
    same_tenant? && post_in_organization?
  end
  
  def destroy?
    owns_record? || admin? # Only like owner or admin can remove
  end
  
  private
  
  def post_in_organization?
    # Ensure the liked post is in the same organization
    record.post.user.organization_id == user.organization_id
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Scope to organization through post relationship
      scope.joins(post: :user).where(users: { organization_id: user.organization_id })
    end
  end
end
# app/policies/like_policy.rb
class LikePolicy < ApplicationPolicy
  def show?
    # Allow viewing like status if post is in same organization
    # This handles both existing likes and checking if user can like a post
    if record.persisted?
      same_tenant? # For existing likes, check tenant
    else
      # For new like objects (checking if user can like), check post tenant
      post_in_organization?
    end
  end
  
  def create?
    # Users can only like posts in their organization
    post_in_organization?
  end
  
  def destroy?
    owns_record? || admin? # Only like owner or admin can remove
  end
  
  private
  
  def post_in_organization?
    # Ensure the liked post is in the same organization
    return false unless record.post
    
    # Check if post belongs to same organization (via post's organization_id)
    if record.post.respond_to?(:organization_id)
      record.post.organization_id == organization.id
    else
      # Fallback: check via post's user organization
      record.post.user.organization_id == organization.id
    end
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Scope to organization through post relationship
      scope.joins(post: :user).where(users: { organization_id: user.organization_id })
    end
  end
end
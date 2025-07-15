class Like < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization)
  
  # Associations
  belongs_to :organization
  belongs_to :user
  belongs_to :post

  # Validations
  validates :organization, presence: true
  validates :user, :post, presence: true
  validates :user_id, uniqueness: { scope: [:post_id, :organization_id], 
                                   message: "You have already liked this post" }
  validate :user_and_post_same_organization
  validate :cross_tenant_access_prevention
  
  # Callbacks
  before_validation :set_organization_from_user
  
  # Instance methods
  def can_be_deleted_by?(current_user)
    return false unless current_user.can_access_organization?(organization)
    self.user == current_user || current_user.enhanced_admin?
  end
  
  def same_organization_as_post?
    user&.organization == post&.organization
  end
  
  def belongs_to_user?(current_user)
    user == current_user
  end
  
  private
  
  def user_and_post_same_organization
    if user && post && user.organization != post.organization
      errors.add(:base, 'User and post must belong to the same organization')
    end
  end
  
  def cross_tenant_access_prevention
    return unless user && post && organization
    
    # Ensure user belongs to the like's organization
    if user.organization != organization
      errors.add(:user, 'cannot like content from different organization')
    end
    
    # Ensure post belongs to the like's organization  
    if post.organization != organization
      errors.add(:post, 'cannot be liked from different organization')
    end
    
    # Double-check all three entities are in same organization
    unless user.organization == post.organization && post.organization == organization
      errors.add(:base, 'Cross-tenant access violation: user, post, and like must be in same organization')
    end
  end
  
  def set_organization_from_user
    self.organization ||= user&.organization
  end
end
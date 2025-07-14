class Like < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization)
  
  # Associations
  belongs_to :organization
  belongs_to :user
  belongs_to :post

  # Validations
  validates :organization, presence: true
  validates :user_id, uniqueness: { scope: [:post_id, :organization_id], 
                                   message: "You have already liked this post" }
  
  # Callbacks
  before_validation :set_organization_from_user
  
  private
  
  def set_organization_from_user
    self.organization ||= user&.organization
  end
end
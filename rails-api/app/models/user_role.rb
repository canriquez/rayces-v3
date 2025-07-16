class UserRole < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Associations
  belongs_to :user
  belongs_to :role
  belongs_to :organization
  
  # Validations
  validates :user, :role, :organization, presence: true
  validates :user_id, uniqueness: { scope: [:role_id, :organization_id], 
                                   message: 'already has this role in the organization' }
  validate :user_and_role_same_organization
  validate :role_belongs_to_organization
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :assigned_recently, -> { where('assigned_at > ?', 1.week.ago) }
  scope :by_role_key, ->(key) { joins(:role).where(roles: { key: key }) }
  
  # Callbacks
  before_validation :set_organization_from_associations
  before_create :set_assigned_at
  
  # Instance methods
  def activate!
    update!(active: true, assigned_at: Time.current)
  end
  
  def deactivate!
    update!(active: false)
  end
  
  def admin?
    role&.admin?
  end
  
  def professional?
    role&.professional?
  end
  
  def secretary?
    role&.secretary?
  end
  
  def client?
    role&.client?
  end
  
  def role_key
    role&.key
  end
  
  def role_name
    role&.name
  end
  
  def can_manage_organization?
    active? && role&.can_manage_organization?
  end
  
  def can_manage_appointments?
    active? && role&.can_manage_appointments?
  end
  
  def can_book_appointments?
    active? && role&.can_book_appointments?
  end
  
  private
  
  def user_and_role_same_organization
    if user && role && user.organization != role.organization
      errors.add(:base, 'User and role must belong to the same organization')
    end
    
    # Also check if explicitly set organization doesn't match
    if organization && user && user.organization != organization
      errors.add(:base, 'User must belong to the specified organization')
    end
  end
  
  def role_belongs_to_organization
    if role && organization && role.organization != organization
      errors.add(:role, 'must belong to the same organization')
    end
  end
  
  def set_organization_from_associations
    # Only set organization automatically if it's not already explicitly set
    # This allows for testing organization mismatches and explicit organization assignment
    if organization.nil?
      self.organization = user&.organization || role&.organization
    end
  end
  
  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
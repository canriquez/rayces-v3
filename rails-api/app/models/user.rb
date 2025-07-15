class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  
  # Multi-tenancy - enabled in all environments
  acts_as_tenant(:organization)
  
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :jwt_authenticatable, jwt_revocation_strategy: self
  
  # Custom email validation instead of Devise's validatable module
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  
  # Associations
  belongs_to :organization
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :posts, dependent: :destroy
  has_many :appointments_as_professional, class_name: 'Appointment', foreign_key: 'professional_id', dependent: :destroy
  has_many :appointments_as_client, class_name: 'Appointment', foreign_key: 'client_id', dependent: :destroy
  has_one :professional_profile, class_name: 'Professional', dependent: :destroy
  has_many :students, foreign_key: 'parent_id', dependent: :destroy
  
  # Role management associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  
  # Enums
  enum role: { admin: 0, professional: 1, staff: 2, guardian: 3 }
  
  # Validations
  validates :email, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :uid, presence: true, uniqueness: true, allow_nil: true # Allow nil for non-Google users
  validates :organization, presence: true
  validates :role, presence: true
  
  # Override Devise email validation to scope to organization
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if conditions[:email].present? && ActsAsTenant.current_tenant
      where(conditions.to_h).where(organization: ActsAsTenant.current_tenant).first
    else
      where(conditions.to_h).first
    end
  end
  
  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :professionals, -> { where(role: :professional) }
  scope :parents, -> { where(role: :guardian) }
  
  # New role management scopes
  scope :with_role_key, ->(role_key) { joins(:roles).where(roles: { key: role_key }) }
  scope :active_users, -> { where(active: true) }
  scope :with_active_roles, -> { joins(:user_roles).where(user_roles: { active: true }) }
  
  # Callbacks
  before_validation :set_default_role, on: :create
  after_create :assign_default_role_in_new_system
  
  # Instance methods
  def jwt_payload
    {
      'sub' => id,
      'email' => email,
      'role' => role,
      'organization_id' => organization_id
    }
  end
  
  def full_name
    "#{first_name} #{last_name}".strip.presence || email
  end
  
  def can_book_appointments?
    guardian? || admin?
  end
  
  def can_manage_appointments?
    professional? || staff? || admin?
  end
  
  # Alias for parent-like behavior since our enum uses :guardian
  def parent?
    guardian?
  end
  
  # Organization access validation
  def can_access_organization?(target_organization)
    organization == target_organization
  end
  
  def super_admin?
    # Add super_admin column later if needed for cross-organization access
    false
  end
  
  # Role management methods (new system)
  def assign_role(role_key)
    target_role = organization.roles.find_by(key: role_key.to_s)
    return false unless target_role
    
    user_roles.find_or_create_by(role: target_role, organization: organization) do |user_role|
      user_role.active = true
      user_role.assigned_at = Time.current
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def remove_role(role_key)
    user_roles.joins(:role)
             .where(roles: { key: role_key.to_s })
             .destroy_all
  end
  
  def has_role?(role_key)
    user_roles.joins(:role)
             .where(roles: { key: role_key.to_s })
             .where(active: true)
             .exists?
  end
  
  def role_keys
    roles.where(user_roles: { active: true }).pluck(:key)
  end
  
  def primary_role
    # Return the most privileged role, or the enum role for backward compatibility
    return roles.find_by(key: 'admin') if has_role?('admin')
    return roles.find_by(key: 'professional') if has_role?('professional')
    return roles.find_by(key: 'secretary') if has_role?('secretary')
    return roles.find_by(key: 'client') if has_role?('client')
    
    # Fallback to enum role for backward compatibility
    organization.roles.find_by(key: role_mapping[role])
  end
  
  def role_mapping
    {
      'admin' => 'admin',
      'professional' => 'professional', 
      'staff' => 'secretary',
      'guardian' => 'client'
    }
  end
  
  # Enhanced role checking methods that consider both systems
  def enhanced_admin?
    admin? || has_role?('admin')
  end
  
  def enhanced_professional?
    professional? || has_role?('professional')
  end
  
  def enhanced_secretary?
    staff? || has_role?('secretary')
  end
  
  def enhanced_client?
    guardian? || has_role?('client')
  end
  
  # Updated capability methods to use enhanced role checking
  def can_book_appointments?
    enhanced_client? || enhanced_admin?
  end
  
  def can_manage_appointments?
    enhanced_professional? || enhanced_secretary? || enhanced_admin?
  end
  
  def can_manage_organization?
    enhanced_admin?
  end
  
  private
  
  def set_default_role
    self.role ||= :guardian
  end
  
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
  
  def assign_default_role_in_new_system
    return unless organization
    
    # Map enum role to new role system
    default_role_key = case role
    when 'admin' then 'admin'
    when 'professional' then 'professional'
    when 'staff' then 'secretary'
    when 'guardian' then 'client'
    else 'client' # Default fallback
    end
    
    # Assign the role in the new system
    assign_role(default_role_key)
  end
end

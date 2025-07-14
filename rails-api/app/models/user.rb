class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization) unless Rails.env.test?
  
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
  
  # Callbacks
  before_validation :set_default_role, on: :create
  
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
  
  private
  
  def set_default_role
    self.role ||= :guardian
  end
  
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end

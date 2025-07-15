# Tenant-scoped Models Example
# This example shows how to properly scope various models to tenants using acts_as_tenant
# Including existing MyHub models (User, Post, Like) and new booking platform models

# app/models/user.rb (Extended from MyHub)
class User < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Existing MyHub associations
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  
  # New booking platform associations
  belongs_to :organization
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_one :professional_profile, dependent: :destroy
  has_one :client_profile, dependent: :destroy
  has_many :appointments_as_client, through: :client_profile, source: :appointments
  has_many :appointments_as_professional, through: :professional_profile, source: :appointments
  has_many :credit_transactions, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: { scope: :organization_id }
  validates :first_name, :last_name, presence: true
  validates :organization, presence: true
  
  # Callbacks
  before_create :assign_default_role
  after_create :create_client_profile
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role_key) { joins(:roles).where(roles: { key: role_key }) }
  scope :professionals, -> { joins(:professional_profile).where.not(professional_profiles: { id: nil }) }
  scope :clients, -> { joins(:client_profile).where.not(client_profiles: { id: nil }) }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def has_role?(role_key)
    roles.exists?(key: role_key)
  end
  
  def assign_role(role_key)
    role = organization.roles.find_by(key: role_key)
    return false unless role
    
    user_roles.find_or_create_by(role: role)
  end
  
  def remove_role(role_key)
    user_roles.joins(:role).where(roles: { key: role_key }).destroy_all
  end
  
  def can_access_organization?(target_organization)
    organization == target_organization || super_admin?
  end
  
  def credit_balance
    credit_transactions.sum(:amount)
  end
  
  def can_book_appointment?
    active? && credit_balance > 0
  end
  
  private
  
  def assign_default_role
    return unless organization
    
    # Don't assign default role if user already has roles
    return if roles.any?
    
    default_role = organization.roles.find_by(key: 'client')
    user_roles.build(role: default_role) if default_role
  end
  
  def create_client_profile
    ClientProfile.create!(user: self, organization: organization)
  end
end

# app/models/post.rb (Extended from MyHub)
class Post < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Associations
  belongs_to :user
  belongs_to :organization
  has_many :likes, dependent: :destroy
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 500 }
  validates :user, :organization, presence: true
  validate :user_belongs_to_organization
  
  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :visible_to_user, ->(user) { where(organization: user.organization) }
  
  # Callbacks
  before_create :set_organization_from_user
  
  # Instance methods
  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end
  
  def toggle_like_by(user)
    return false unless user && user.organization == organization
    
    like = likes.find_by(user: user)
    if like
      like.destroy
      false
    else
      likes.create!(user: user)
      true
    end
  end
  
  private
  
  def user_belongs_to_organization
    if user && organization && user.organization != organization
      errors.add(:user, 'must belong to the same organization')
    end
  end
  
  def set_organization_from_user
    self.organization ||= user&.organization
  end
end

# app/models/appointment.rb (New booking platform model)
class Appointment < ApplicationRecord
  include AASM
  
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Associations
  belongs_to :organization
  belongs_to :client_profile
  belongs_to :professional_profile
  belongs_to :service
  has_one :client, through: :client_profile, source: :user
  has_one :professional, through: :professional_profile, source: :user
  has_many :appointment_notes, dependent: :destroy
  has_one :credit_transaction, dependent: :nullify
  
  # Validations
  validates :organization, :client_profile, :professional_profile, :service, presence: true
  validates :start_time, :end_time, presence: true
  validate :start_time_before_end_time
  validate :no_overlapping_appointments
  validate :within_availability_schedule
  validates_uniqueness_to_tenant :external_id, allow_blank: true
  
  # State machine
  aasm column: 'status' do
    state :draft, initial: true
    state :pre_confirmed
    state :confirmed
    state :executed
    state :cancelled
    
    event :pre_confirm do
      transitions from: :draft, to: :pre_confirmed
      after do
        set_expiration_time
        send_pre_confirmation_notification
      end
    end
    
    event :confirm do
      transitions from: [:draft, :pre_confirmed], to: :confirmed
      after do
        charge_credits
        send_confirmation_notification
      end
    end
    
    event :execute do
      transitions from: :confirmed, to: :executed
      after do
        create_appointment_summary
        send_completion_notification
      end
    end
    
    event :cancel do
      transitions from: [:draft, :pre_confirmed, :confirmed], to: :cancelled
      after do
        refund_credits if confirmed?
        send_cancellation_notification
      end
    end
  end
  
  # Scopes
  scope :upcoming, -> { where('start_time > ?', Time.current).order(:start_time) }
  scope :past, -> { where('end_time < ?', Time.current).order(start_time: :desc) }
  scope :today, -> { where(start_time: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(start_time: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :by_professional, ->(professional) { joins(:professional_profile).where(professional_profiles: { user_id: professional.id }) }
  scope :by_client, ->(client) { joins(:client_profile).where(client_profiles: { user_id: client.id }) }
  
  # Callbacks
  before_validation :set_organization_from_associations
  before_create :generate_external_id
  
  # Instance methods
  def duration_in_minutes
    ((end_time - start_time) / 60).to_i
  end
  
  def cancellable?
    (draft? || pre_confirmed? || confirmed?) && 
    start_time > 24.hours.from_now
  end
  
  def can_be_cancelled_by?(user)
    return false unless cancellable?
    
    user == client || 
    user == professional || 
    user.has_role?('admin') || 
    user.has_role?('secretary')
  end
  
  def expired?
    pre_confirmed? && expiration_time < Time.current
  end
  
  private
  
  def set_organization_from_associations
    self.organization ||= client_profile&.organization || professional_profile&.organization
  end
  
  def generate_external_id
    self.external_id = "#{organization.subdomain}-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end
  
  def start_time_before_end_time
    return unless start_time && end_time
    
    if start_time >= end_time
      errors.add(:end_time, 'must be after start time')
    end
  end
  
  def no_overlapping_appointments
    return unless professional_profile && start_time && end_time
    
    overlapping = Appointment.confirmed
                            .where(professional_profile: professional_profile)
                            .where.not(id: id)
                            .where('(start_time < ? AND end_time > ?) OR (start_time < ? AND end_time > ?)',
                                   end_time, start_time, end_time, start_time)
    
    if overlapping.exists?
      errors.add(:start_time, 'conflicts with another appointment')
    end
  end
  
  def within_availability_schedule
    # Check if appointment is within professional's availability
    # Implementation depends on availability schedule model
  end
  
  def set_expiration_time
    self.expiration_time = 24.hours.from_now
    save!
  end
  
  def charge_credits
    return if credit_transaction.present?
    
    CreditTransaction.create!(
      user: client,
      organization: organization,
      amount: -service.credit_cost,
      transaction_type: 'appointment_charge',
      description: "Appointment with #{professional.full_name}",
      appointment: self
    )
  end
  
  def refund_credits
    return unless credit_transaction.present?
    
    CreditTransaction.create!(
      user: client,
      organization: organization,
      amount: service.credit_cost,
      transaction_type: 'appointment_refund',
      description: "Refund for cancelled appointment",
      appointment: self
    )
  end
  
  def send_pre_confirmation_notification
    AppointmentMailer.pre_confirmation(self).deliver_later
  end
  
  def send_confirmation_notification
    AppointmentMailer.confirmation(self).deliver_later
  end
  
  def send_completion_notification
    AppointmentMailer.completion(self).deliver_later
  end
  
  def send_cancellation_notification
    AppointmentMailer.cancellation(self).deliver_later
  end
  
  def create_appointment_summary
    # Create AI-generated summary if enabled
    if organization.feature_enabled?('ai_reports')
      AppointmentSummaryJob.perform_later(self)
    end
  end
end

# app/models/role.rb
class Role < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Associations
  belongs_to :organization
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  
  # Validations
  validates :name, :key, presence: true
  validates :key, uniqueness: { scope: :organization_id }
  validates :key, inclusion: { in: %w[admin professional secretary client] }
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Class methods
  def self.default_roles
    [
      { key: 'admin', name: 'Administrator', description: 'Full organization access' },
      { key: 'professional', name: 'Professional', description: 'Can manage appointments and students' },
      { key: 'secretary', name: 'Secretary', description: 'Can manage appointments and billing' },
      { key: 'client', name: 'Client', description: 'Can book appointments and view progress' }
    ]
  end
end

# app/models/user_role.rb
class UserRole < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization
  
  # Associations
  belongs_to :user
  belongs_to :role
  belongs_to :organization
  
  # Validations
  validates :user, :role, :organization, presence: true
  validates :user_id, uniqueness: { scope: [:role_id, :organization_id] }
  validate :user_and_role_same_organization
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  before_validation :set_organization_from_associations
  
  private
  
  def user_and_role_same_organization
    if user && role && user.organization != role.organization
      errors.add(:base, 'User and role must belong to the same organization')
    end
  end
  
  def set_organization_from_associations
    self.organization ||= user&.organization || role&.organization
  end
end
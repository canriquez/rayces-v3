class Professional < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization) unless Rails.env.test?
  
  # Associations
  belongs_to :organization
  belongs_to :user
  has_many :appointments, foreign_key: 'professional_id', primary_key: 'user_id', dependent: :destroy
  has_many :students, through: :appointments
  
  # Validations
  validates :organization, presence: true
  validates :user, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :session_duration_minutes, numericality: { greater_than: 0 }
  validates :hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :license_number, presence: true, if: :license_required?
  
  validate :user_has_professional_role
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_specialization, ->(spec) { where(specialization: spec) }
  scope :available, -> { active.joins(:user).where(users: { role: :professional }) }
  
  # Delegations
  delegate :email, :full_name, :first_name, :last_name, :phone, to: :user
  
  # Instance methods
  def display_name
    title.present? ? "#{title} #{full_name}" : full_name
  end
  
  def available_on?(date, time)
    # Check availability for specific date and time
    # This would check against the availability JSON structure
    # Example structure: { "monday": { "start": "09:00", "end": "17:00" } }
    day_name = date.strftime('%A').downcase
    day_availability = availability[day_name]
    
    return false unless day_availability.present?
    
    start_time = Time.parse(day_availability['start'])
    end_time = Time.parse(day_availability['end'])
    
    time >= start_time && time <= end_time
  end
  
  def next_available_slot(from_date = Date.current)
    # Find next available time slot
    # Implementation would check availability and existing appointments
  end
  
  def booked_slots_for_date(date)
    appointments
      .where.not(state: [:cancelled, :draft])
      .for_date(date)
      .pluck(:scheduled_at, :duration_minutes)
  end
  
  private
  
  def user_has_professional_role
    unless user&.professional?
      errors.add(:user, "must have professional role")
    end
  end
  
  def license_required?
    # Determine if license is required based on specialization
    # This could be configured per organization
    %w[psychology psychiatry therapy].include?(specialization&.downcase)
  end
end
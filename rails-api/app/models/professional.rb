class Professional < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization) unless Rails.env.test?
  
  # Associations
  belongs_to :organization
  belongs_to :user
  has_many :appointments, foreign_key: 'professional_id', primary_key: 'user_id', dependent: :destroy
  has_many :students, through: :appointments
  has_many :availability_rules, dependent: :destroy
  has_many :time_slots, dependent: :destroy
  
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
  
  def available_on?(day_name)
    # Check if professional is available on a specific day
    # Example structure: { "monday": { "start": "09:00", "end": "17:00" } }
    return false unless availability.is_a?(Hash)
    
    day_key = day_name.to_s.downcase
    availability.key?(day_key) && availability[day_key].present?
  end
  
  def available_at?(datetime)
    # Check if professional is available at a specific datetime
    return false unless datetime.is_a?(Time) || datetime.is_a?(DateTime) || datetime.is_a?(Date)
    return false unless availability.is_a?(Hash)
    
    # Convert Date to Time if needed
    if datetime.is_a?(Date)
      # Date objects don't have time components, so assume start of day
      datetime = datetime.to_time
    end
    
    day_name = datetime.strftime('%A').downcase
    day_availability = availability[day_name]
    
    return false unless day_availability.present?
    
    # Parse the start and end times from availability
    start_time = Time.parse(day_availability['start'])
    end_time = Time.parse(day_availability['end'])
    
    # Compare only the time portion
    time_only = datetime.strftime('%H:%M')
    start_time_str = start_time.strftime('%H:%M')
    end_time_str = end_time.strftime('%H:%M')
    
    time_only >= start_time_str && time_only <= end_time_str
  end
  
  def has_conflicting_appointment?(datetime, duration_minutes = 60)
    # Check if there's a conflicting appointment at the given time
    return false unless datetime.is_a?(Time) || datetime.is_a?(DateTime)
    
    end_time = datetime + duration_minutes.minutes
    
    # Use the appointments association to check for conflicts
    # Exclude draft and cancelled appointments
    appointments
      .where.not(state: ['cancelled', 'draft'])
      .where(
        '(scheduled_at < ? AND scheduled_at + INTERVAL \'1 minute\' * duration_minutes > ?) OR ' \
        '(scheduled_at < ? AND scheduled_at + INTERVAL \'1 minute\' * duration_minutes > ?)',
        end_time, datetime, end_time, datetime
      )
      .exists?
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
# Appointment Model with Complete Validation Logic
# This demonstrates comprehensive Rails model validation with business logic

class Appointment < ApplicationRecord
  acts_as_tenant :organization
  
  # AASM State Machine
  include AASM
  
  aasm column: :state do
    state :draft, initial: true
    state :pre_confirmed
    state :confirmed  
    state :executed
    state :cancelled
    
    event :pre_confirm do
      transitions from: :draft, to: :pre_confirmed, guard: :can_be_pre_confirmed?
      
      after do
        self.expires_at = 24.hours.from_now
        self.pre_confirmed_at = Time.current
      end
    end
    
    event :confirm do
      transitions from: :pre_confirmed, to: :confirmed, guard: :can_be_confirmed?
      
      after do
        self.confirmed_at = Time.current
        self.expires_at = nil
      end
    end
    
    event :execute do
      transitions from: :confirmed, to: :executed, guard: :can_be_executed?
      
      after do
        self.executed_at = Time.current
      end
    end
    
    event :cancel do
      transitions from: [:draft, :pre_confirmed, :confirmed], to: :cancelled
      
      after do
        self.cancelled_at = Time.current
      end
    end
  end
  
  # Associations
  belongs_to :organization
  belongs_to :professional
  belongs_to :student
  has_one :user, through: :professional
  
  # Validations
  validates :scheduled_at, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0, less_than: 480 }
  validates :appointment_type, presence: true
  validates :professional_id, presence: true
  validates :student_id, presence: true
  
  # Custom validations
  validate :scheduled_at_is_in_future, on: :create
  validate :professional_is_available
  validate :no_overlapping_appointments
  validate :appointment_within_working_hours
  validate :professional_belongs_to_organization
  validate :student_belongs_to_organization
  validate :minimum_advance_booking
  
  # Scopes
  scope :upcoming, -> { where('scheduled_at > ?', Time.current) }
  scope :past, -> { where('scheduled_at < ?', Time.current) }
  scope :today, -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :for_professional, ->(professional_id) { where(professional_id: professional_id) }
  scope :for_student, ->(student_id) { where(student_id: student_id) }
  scope :by_state, ->(state) { where(state: state) }
  
  # Class methods
  def self.conflicting_appointments(professional_id, scheduled_at, duration, exclude_id = nil)
    start_time = scheduled_at
    end_time = scheduled_at + duration.minutes
    
    query = where(professional_id: professional_id)
            .where.not(state: ['cancelled', 'executed'])
            .where(
              '(scheduled_at <= ? AND scheduled_at + INTERVAL duration MINUTE > ?) OR 
               (scheduled_at < ? AND scheduled_at + INTERVAL duration MINUTE >= ?)',
              start_time, start_time, end_time, end_time
            )
    
    query = query.where.not(id: exclude_id) if exclude_id
    query
  end
  
  # Instance methods
  def end_time
    scheduled_at + duration.minutes
  end
  
  def can_be_cancelled?
    draft? || pre_confirmed? || (confirmed? && scheduled_at > 24.hours.from_now)
  end
  
  def eligible_for_credit?
    return false unless cancelled?
    
    case state_before_cancel
    when 'confirmed'
      # Credit if cancelled more than 24 hours in advance
      cancelled_at <= scheduled_at - 24.hours
    when 'pre_confirmed'
      # Always credit for pre-confirmed appointments
      true
    else
      false
    end
  end
  
  def credit_amount
    # Calculate credit amount based on timing and cancellation policy
    if eligible_for_credit?
      hours_before_appointment = (scheduled_at - cancelled_at) / 1.hour
      
      case hours_before_appointment
      when 48..Float::INFINITY
        1.0 # Full credit
      when 24..48
        0.5 # Half credit
      else
        0.0 # No credit
      end
    else
      0.0
    end
  end
  
  def expired?
    pre_confirmed? && expires_at && expires_at <= Time.current
  end
  
  def expires_soon?
    pre_confirmed? && expires_at && expires_at <= 1.hour.from_now
  end
  
  private
  
  def scheduled_at_is_in_future
    return unless scheduled_at
    
    if scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
  
  def professional_is_available
    return unless professional && scheduled_at && duration
    
    unless professional.available_at?(scheduled_at)
      errors.add(:scheduled_at, "professional is not available at this time")
    end
  end
  
  def no_overlapping_appointments
    return unless professional_id && scheduled_at && duration
    
    conflicting = self.class.conflicting_appointments(
      professional_id, 
      scheduled_at, 
      duration, 
      persisted? ? id : nil
    )
    
    if conflicting.any?
      errors.add(:scheduled_at, "conflicts with existing appointment")
    end
  end
  
  def appointment_within_working_hours
    return unless professional && scheduled_at
    
    day_of_week = scheduled_at.strftime('%A').downcase
    working_hours = professional.working_hours&.dig(day_of_week)
    
    if working_hours.nil? || working_hours['start'].nil?
      errors.add(:scheduled_at, "professional is not available on #{day_of_week.capitalize}")
      return
    end
    
    start_time = Time.parse(working_hours['start'])
    end_time = Time.parse(working_hours['end'])
    appointment_start = scheduled_at.strftime('%H:%M')
    appointment_end = end_time.strftime('%H:%M')
    
    if appointment_start < start_time.strftime('%H:%M') || appointment_end > end_time.strftime('%H:%M')
      errors.add(:scheduled_at, "appointment is outside professional's working hours")
    end
  end
  
  def professional_belongs_to_organization
    return unless professional
    
    if professional.organization_id != organization_id
      errors.add(:professional, "must belong to the same organization")
    end
  end
  
  def student_belongs_to_organization
    return unless student
    
    if student.organization_id != organization_id
      errors.add(:student, "must belong to the same organization")
    end
  end
  
  def minimum_advance_booking
    return unless scheduled_at
    
    minimum_advance = 2.hours
    
    if scheduled_at < minimum_advance.from_now
      errors.add(:scheduled_at, "must be at least #{minimum_advance.inspect} in advance")
    end
  end
  
  def can_be_pre_confirmed?
    draft? && scheduled_at && scheduled_at > Time.current
  end
  
  def can_be_confirmed?
    pre_confirmed? && !expired?
  end
  
  def can_be_executed?
    confirmed? && scheduled_at <= Time.current
  end
  
  def state_before_cancel
    @state_before_cancel ||= aasm.from_state.to_s
  end
end
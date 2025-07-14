class Appointment < ApplicationRecord
  include AASM
  
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization) unless Rails.env.test?
  
  # Associations
  belongs_to :organization
  belongs_to :professional, class_name: 'User'
  belongs_to :client, class_name: 'User'
  belongs_to :student, optional: true
  belongs_to :cancelled_by, class_name: 'User', optional: true
  
  # Validations
  validates :organization, presence: true
  validates :professional, presence: true
  validates :client, presence: true
  validates :scheduled_at, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :state, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :credits_used, numericality: { greater_than: 0 }, allow_nil: true
  
  validate :scheduled_in_future, on: :create
  validate :professional_available
  validate :no_overlapping_appointments
  
  # Scopes
  scope :upcoming, -> { where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :past, -> { where('scheduled_at <= ?', Time.current).order(scheduled_at: :desc) }
  scope :for_date, ->(date) { where(scheduled_at: date.beginning_of_day..date.end_of_day) }
  scope :for_professional, ->(professional) { where(professional: professional) }
  scope :for_client, ->(client) { where(client: client) }
  
  # AASM State Machine
  aasm column: :state do
    state :draft, initial: true
    state :pre_confirmed
    state :confirmed
    state :executed
    state :cancelled
    
    event :pre_confirm do
      transitions from: :draft, to: :pre_confirmed
      after do
        # Schedule reminder for 24 hours
        AppointmentReminderWorker.perform_in(24.hours, id)
        # Notify client
        EmailNotificationWorker.perform_async(client_id, 'appointment_confirmation_reminder', { 'appointment_id' => id })
      end
    end
    
    event :confirm do
      transitions from: :pre_confirmed, to: :confirmed
      after do
        # Notify both professional and client
        EmailNotificationWorker.perform_async(professional_id, 'appointment_confirmed', { 'appointment_id' => id })
        EmailNotificationWorker.perform_async(client_id, 'appointment_confirmed', { 'appointment_id' => id })
      end
    end
    
    event :execute do
      transitions from: :confirmed, to: :executed, guard: :appointment_time_passed?
      after do
        # Mark as completed, potentially trigger billing
        log_execution
      end
    end
    
    event :cancel do
      transitions from: [:draft, :pre_confirmed, :confirmed], to: :cancelled
      after do |user|
        self.cancelled_at = Time.current
        self.cancelled_by = user
        save!
        
        # Issue credits if applicable
        issue_cancellation_credits if should_issue_credits?
        
        # Notify affected parties
        notify_cancellation
      end
    end
  end
  
  # Instance methods
  def ends_at
    scheduled_at + duration_minutes.minutes
  end
  
  def appointment_time_passed?
    scheduled_at <= Time.current
  end
  
  def should_issue_credits?
    uses_credits && confirmed? && scheduled_at > 24.hours.from_now
  end
  
  private
  
  def scheduled_in_future
    if scheduled_at.present? && scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
  
  def professional_available
    # Check if professional is available at this time
    # This would check against their availability schedule
    # Implementation depends on availability model
  end
  
  def no_overlapping_appointments
    return unless scheduled_at.present? && duration_minutes.present?
    
    overlapping = Appointment
      .where(professional: professional)
      .where.not(state: [:cancelled, :draft])
      .where.not(id: id)
      .where(
        "(scheduled_at, scheduled_at + interval '1 minute' * duration_minutes) OVERLAPS (?, ?)",
        scheduled_at,
        ends_at
      )
    
    if overlapping.exists?
      errors.add(:scheduled_at, "conflicts with another appointment")
    end
  end
  
  def issue_cancellation_credits
    # Logic to issue credits back to client
    # This would interact with a credits/billing system
    Rails.logger.info "Would issue #{credits_used} credits back to client #{client_id}"
  end
  
  def notify_cancellation
    EmailNotificationWorker.perform_async(professional_id, 'appointment_cancelled', { 'appointment_id' => id })
    EmailNotificationWorker.perform_async(client_id, 'appointment_cancelled', { 'appointment_id' => id })
  end
  
  def log_execution
    Rails.logger.info "Appointment #{id} executed at #{Time.current}"
  end
end
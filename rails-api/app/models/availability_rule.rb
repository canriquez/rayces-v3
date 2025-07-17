class AvailabilityRule < ApplicationRecord
  acts_as_tenant(:organization)
  
  belongs_to :professional
  
  DAYS_OF_WEEK = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }.freeze
  
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :professional_id, uniqueness: { 
    scope: [:organization_id, :day_of_week, :start_time], 
    message: "already has a rule for this day and time" 
  }
  
  validate :end_time_after_start_time
  
  scope :active, -> { where(active: true) }
  scope :for_day, ->(day) { where(day_of_week: day) }
  scope :ordered, -> { order(:day_of_week, :start_time) }
  
  def day_name
    DAYS_OF_WEEK.key(day_of_week).to_s.capitalize
  end
  
  def time_range
    "#{start_time.strftime('%H:%M')} - #{end_time.strftime('%H:%M')}"
  end
  
  def overlaps_with?(other_rule)
    return false if other_rule.day_of_week != day_of_week
    return false unless active && other_rule.active
    
    # Check if time ranges overlap
    start_time < other_rule.end_time && end_time > other_rule.start_time
  end
  
  def duration_minutes
    ((end_time - start_time) / 60).to_i
  end
  
  private
  
  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
class TimeSlot < ApplicationRecord
  acts_as_tenant(:organization)
  
  belongs_to :professional
  belongs_to :appointment, optional: true
  
  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :professional_id, uniqueness: { 
    scope: [:organization_id, :date, :start_time],
    message: "already has a time slot for this date and time"
  }
  
  validate :end_time_after_start_time
  validate :no_overlapping_slots
  
  scope :available, -> { where(available: true, appointment_id: nil) }
  scope :booked, -> { where(available: false).or(where.not(appointment_id: nil)) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :future, -> { where('date >= ?', Date.current) }
  scope :past, -> { where('date < ?', Date.current) }
  scope :ordered, -> { order(:date, :start_time) }
  
  before_save :update_availability
  
  def book!(appointment)
    transaction do
      raise "Time slot already booked" unless available && appointment_id.nil?
      
      self.appointment = appointment
      self.available = false
      save!
    end
  end
  
  def release!
    transaction do
      self.appointment = nil
      self.available = true
      save!
    end
  end
  
  def duration_minutes
    ((end_time - start_time) / 60).to_i
  end
  
  def datetime_start
    DateTime.parse("#{date} #{start_time.strftime('%H:%M:%S')}")
  end
  
  def datetime_end
    DateTime.parse("#{date} #{end_time.strftime('%H:%M:%S')}")
  end
  
  def overlaps_with?(other_slot)
    return false if other_slot.date != date
    return false if other_slot.professional_id != professional_id
    
    # Check if time ranges overlap
    start_time < other_slot.end_time && end_time > other_slot.start_time
  end
  
  private
  
  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
  
  def no_overlapping_slots
    return unless date && start_time && end_time && professional_id
    
    overlapping = TimeSlot
      .where(professional_id: professional_id, date: date)
      .where.not(id: id)
      .where('start_time < ? AND end_time > ?', end_time, start_time)
    
    if organization_id
      overlapping = overlapping.where(organization_id: organization_id)
    end
    
    if overlapping.exists?
      errors.add(:base, "Time slot overlaps with existing slot")
    end
  end
  
  def update_availability
    self.available = appointment_id.nil?
    true
  end
end
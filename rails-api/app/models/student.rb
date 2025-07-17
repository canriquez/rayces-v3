class Student < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization) unless Rails.env.test?
  
  # Associations
  belongs_to :organization
  belongs_to :parent, class_name: 'User'
  has_many :appointments, dependent: :destroy
  has_many :professionals, through: :appointments
  
  # Validations
  validates :organization, presence: true
  validates :parent, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true, if: :date_of_birth_required?
  validates :gender, inclusion: { in: %w[male female other prefer_not_to_say] }, allow_blank: true
  
  validate :parent_has_correct_role
  validate :age_appropriate
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_parent, ->(parent) { where(parent: parent) }
  scope :by_grade, ->(grade) { where(grade_level: grade) }
  scope :with_appointments, -> { joins(:appointments).distinct }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def age
    return nil unless date_of_birth.present?
    
    today = Date.current
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end
  
  def minor?
    age.present? && age < 18
  end
  
  def upcoming_appointments
    appointments.upcoming
  end
  
  def past_appointments
    appointments.past
  end
  
  def add_emergency_contact(contact_info)
    # contact_info should include: name, relationship, phone, email
    self.emergency_contacts ||= []
    self.emergency_contacts << contact_info
    save
  end
  
  def primary_emergency_contact
    emergency_contacts.first
  end
  
  private
  
  def parent_has_correct_role
    unless parent&.guardian? || parent&.admin?
      errors.add(:parent, "must have guardian or admin role")
    end
  end
  
  def age_appropriate
    if date_of_birth.present? && date_of_birth > Date.current
      errors.add(:date_of_birth, "cannot be in the future")
    elsif date_of_birth.present? && age > 100
      errors.add(:date_of_birth, "seems incorrect (age over 100)")
    elsif date_of_birth.present? && age > 18
      errors.add(:date_of_birth, "student cannot be older than 18 years")
    end
  end
  
  def date_of_birth_required?
    # Can be configured per organization
    true
  end
end
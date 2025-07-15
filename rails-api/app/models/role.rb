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
  validates :name, length: { minimum: 2, maximum: 50 }
  validates :description, length: { maximum: 255 }, allow_blank: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_key, ->(key) { where(key: key) }
  
  # Callbacks
  before_validation :normalize_key
  
  # Class methods
  def self.default_roles
    [
      { key: 'admin', name: 'Administrator', description: 'Full organization access and management' },
      { key: 'professional', name: 'Professional', description: 'Can manage appointments, students, and provide services' },
      { key: 'secretary', name: 'Secretary', description: 'Can manage appointments, billing, and client support' },
      { key: 'client', name: 'Client', description: 'Can book appointments and view student progress' }
    ]
  end
  
  def self.create_defaults_for_organization(organization)
    ActsAsTenant.with_tenant(organization) do
      default_roles.each do |role_data|
        find_or_create_by(key: role_data[:key]) do |role|
          role.name = role_data[:name]
          role.description = role_data[:description]
          role.organization = organization
        end
      end
    end
  end
  
  # Instance methods
  def admin?
    key == 'admin'
  end
  
  def professional?
    key == 'professional'
  end
  
  def secretary?
    key == 'secretary'
  end
  
  def client?
    key == 'client'
  end
  
  def can_manage_organization?
    admin?
  end
  
  def can_manage_appointments?
    admin? || professional? || secretary?
  end
  
  def can_book_appointments?
    admin? || client?
  end
  
  def display_name
    "#{name} (#{key})"
  end
  
  private
  
  def normalize_key
    self.key = key&.downcase&.strip
  end
end
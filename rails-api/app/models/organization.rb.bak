class Organization < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true, 
            format: { with: /\A[a-z0-9\-]+\z/, 
                     message: "only allows lowercase letters, numbers, and hyphens" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Associations
  has_many :users, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :professionals, dependent: :destroy
  has_many :students, dependent: :destroy
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  before_validation :normalize_subdomain
  
  # Class methods
  def self.find_by_subdomain(subdomain)
    find_by(subdomain: subdomain&.downcase)
  end
  
  # Instance methods
  def to_param
    subdomain
  end
  
  private
  
  def normalize_subdomain
    self.subdomain = subdomain&.downcase&.strip
  end
end
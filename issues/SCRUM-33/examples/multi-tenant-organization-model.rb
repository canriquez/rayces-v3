# Multi-tenant Organization Model Example with acts_as_tenant
# This example shows a complete organization model setup for a multi-tenant Rails application
# Based on best practices from acts_as_tenant documentation and real-world implementations

# app/models/organization.rb
class Organization < ApplicationRecord
  # Associations - all tenant-scoped models
  has_many :users, dependent: :restrict_with_error
  has_many :posts, dependent: :restrict_with_error
  has_many :likes, dependent: :restrict_with_error
  has_many :professional_profiles, dependent: :restrict_with_error
  has_many :appointments, dependent: :restrict_with_error
  has_many :services, dependent: :restrict_with_error
  has_many :roles, dependent: :restrict_with_error
  has_many :user_roles, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9\-]+\z/, message: 'only lowercase letters, numbers, and hyphens' }
  validates :domain, uniqueness: { case_sensitive: false, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :country, inclusion: { in: %w[AR US BR CL UY MX CO PE] }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  
  # Callbacks
  before_validation :normalize_subdomain
  after_create :setup_default_roles
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :with_subdomain, ->(subdomain) { where(subdomain: subdomain) }
  scope :by_country, ->(country) { where(country: country) }
  
  # Settings JSON structure
  # {
  #   "features": {
  #     "booking_enabled": true,
  #     "ai_reports": false,
  #     "max_professionals": 10
  #   },
  #   "branding": {
  #     "primary_color": "#007bff",
  #     "logo_url": "https://..."
  #   },
  #   "notifications": {
  #     "email_enabled": true,
  #     "whatsapp_enabled": false
  #   }
  # }
  
  # Instance methods
  def full_name
    "#{name} (#{subdomain})"
  end
  
  def activate!
    update!(active: true)
  end
  
  def deactivate!
    update!(active: false)
  end
  
  def feature_enabled?(feature_key)
    settings.dig('features', feature_key.to_s) || false
  end
  
  def update_feature(feature_key, enabled)
    self.settings ||= {}
    self.settings['features'] ||= {}
    self.settings['features'][feature_key.to_s] = enabled
    save!
  end
  
  def within_professional_limit?
    return true unless settings.dig('features', 'max_professionals')
    professional_profiles.active.count < settings.dig('features', 'max_professionals')
  end
  
  # Class methods
  def self.find_by_domain_or_subdomain(host)
    subdomain = extract_subdomain(host)
    
    # First try to find by custom domain
    org = find_by(domain: host, active: true)
    return org if org
    
    # Then try to find by subdomain
    find_by(subdomain: subdomain, active: true) if subdomain.present?
  end
  
  private
  
  def normalize_subdomain
    self.subdomain = subdomain&.downcase&.strip
  end
  
  def setup_default_roles
    default_roles = [
      { key: 'admin', name: 'Administrator', description: 'Full organization access' },
      { key: 'professional', name: 'Professional', description: 'Can manage appointments and students' },
      { key: 'secretary', name: 'Secretary', description: 'Can manage appointments and billing' },
      { key: 'client', name: 'Client', description: 'Can book appointments and view progress' }
    ]
    
    default_roles.each do |role_attrs|
      roles.create!(role_attrs)
    end
  end
  
  def self.extract_subdomain(host)
    return nil if host.blank?
    
    # Remove port if present
    host = host.split(':').first
    
    # Split by dots
    parts = host.split('.')
    
    # If it's a custom domain or localhost, return nil
    return nil if parts.size < 3
    
    # Return the first part as subdomain
    parts.first
  end
end

# Migration for organizations table
class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :domain
      t.text :description
      t.string :phone
      t.string :email
      t.string :address
      t.string :city
      t.string :state
      t.string :country, default: 'AR'
      t.string :timezone, default: 'America/Argentina/Buenos_Aires'
      t.boolean :active, default: true
      t.json :settings, default: {}
      
      # Billing information
      t.string :billing_name
      t.string :billing_tax_id
      t.string :billing_address
      t.string :billing_email
      
      # Subscription information
      t.string :subscription_plan
      t.datetime :subscription_expires_at
      t.integer :subscription_status, default: 0 # enum: trial, active, expired, cancelled
      
      t.timestamps
    end
    
    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :domain, unique: true
    add_index :organizations, :active
    add_index :organizations, :subscription_expires_at
    add_index :organizations, :country
  end
end
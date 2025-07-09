# Multi-Tenancy Setup Example with acts_as_tenant
# This file demonstrates how to set up multi-tenancy for the Rayces booking platform

# config/initializers/acts_as_tenant.rb
ActsAsTenant.configure do |config|
  # Require tenant for all operations (can be disabled for testing)
  config.require_tenant = true
  
  # Customize the query for loading the tenant in background jobs
  config.job_scope = -> { all }
  
  # Configure tenant change hook for additional setup
  config.tenant_change_hook = lambda do |tenant|
    if tenant.present?
      Rails.logger.info "Changed tenant to #{tenant.subdomain} (#{tenant.id})"
      # You can add additional setup here, like setting current organization context
    end
  end
end

# app/models/organization.rb
class Organization < ApplicationRecord
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  
  has_many :users, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :professionals, dependent: :destroy
  has_many :students, dependent: :destroy
  
  # Subdomain validation for multi-tenancy
  validates :subdomain, format: { with: /\A[a-z0-9]+\z/, message: "only lowercase letters and numbers" }
  validates :subdomain, length: { minimum: 3, maximum: 63 }
  
  # Reserved subdomains
  RESERVED_SUBDOMAINS = %w[www admin api app mail ftp localhost].freeze
  validates :subdomain, exclusion: { in: RESERVED_SUBDOMAINS }
  
  before_validation :normalize_subdomain
  
  private
  
  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
  end
end

# app/models/user.rb
class User < ApplicationRecord
  acts_as_tenant(:organization)
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  enum role: { parent: 0, professional: 1, staff: 2, admin: 3 }
  
  validates :email, presence: true, uniqueness: { scope: :organization_id }
  validates :role, presence: true
  
  belongs_to :organization
  has_many :appointments, dependent: :destroy
  has_many :student_relationships, dependent: :destroy
  has_many :students, through: :student_relationships
end

# app/models/appointment.rb
class Appointment < ApplicationRecord
  acts_as_tenant(:organization)
  
  include AASM
  
  belongs_to :organization
  belongs_to :professional, class_name: 'User'
  belongs_to :student
  belongs_to :parent, class_name: 'User'
  
  validates :start_time, :end_time, presence: true
  validates :professional_id, :student_id, :parent_id, presence: true
  
  # AASM state machine for appointment lifecycle
  aasm column: :status do
    state :draft, initial: true
    state :pre_confirmed
    state :confirmed
    state :executed
    state :cancelled
    
    event :pre_confirm do
      transitions from: :draft, to: :pre_confirmed
    end
    
    event :confirm do
      transitions from: :pre_confirmed, to: :confirmed
    end
    
    event :execute do
      transitions from: :confirmed, to: :executed
    end
    
    event :cancel do
      transitions from: [:draft, :pre_confirmed, :confirmed], to: :cancelled
    end
  end
  
  scope :for_professional, ->(professional) { where(professional: professional) }
  scope :for_student, ->(student) { where(student: student) }
  scope :for_parent, ->(parent) { where(parent: parent) }
  scope :upcoming, -> { where('start_time > ?', Time.current) }
  scope :past, -> { where('start_time < ?', Time.current) }
end

# app/models/student.rb
class Student < ApplicationRecord
  acts_as_tenant(:organization)
  
  belongs_to :organization
  has_many :appointments, dependent: :destroy
  has_many :student_relationships, dependent: :destroy
  has_many :parents, through: :student_relationships, source: :user
  
  validates :name, presence: true
  validates :date_of_birth, presence: true
  validates :organization_id, presence: true
  
  # Unique validation within tenant scope
  validates_uniqueness_to_tenant :email, allow_blank: true
  validates_uniqueness_to_tenant :identification_number, allow_blank: true
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions
  include Pundit::Authorization
  
  # Set current tenant by subdomain
  set_current_tenant_by_subdomain(:organization, :subdomain)
  
  # Alternative: Set tenant manually in a before_action
  # set_current_tenant_through_filter
  # before_action :set_tenant
  
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :no_tenant_set
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def set_tenant
    subdomain = request.subdomain
    organization = Organization.find_by(subdomain: subdomain)
    
    if organization
      set_current_tenant(organization)
    else
      render json: { error: 'Organization not found' }, status: :not_found
    end
  end
  
  def no_tenant_set
    render json: { error: 'No tenant set. Please access via subdomain.' }, status: :bad_request
  end
  
  def user_not_authorized
    render json: { error: 'Not authorized' }, status: :forbidden
  end
end

# app/controllers/api/v1/appointments_controller.rb
class Api::V1::AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: [:show, :update, :destroy]
  
  def index
    @appointments = policy_scope(Appointment.all)
    # All appointments will be automatically scoped to current tenant
    render json: @appointments
  end
  
  def show
    authorize @appointment
    render json: @appointment
  end
  
  def create
    @appointment = Appointment.new(appointment_params)
    # Tenant is automatically set by acts_as_tenant
    authorize @appointment
    
    if @appointment.save
      render json: @appointment, status: :created
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @appointment
    
    if @appointment.update(appointment_params)
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @appointment
    @appointment.destroy
    head :no_content
  end
  
  private
  
  def set_appointment
    # Find will automatically scope to current tenant
    @appointment = Appointment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Appointment not found' }, status: :not_found
  end
  
  def appointment_params
    params.require(:appointment).permit(:professional_id, :student_id, :parent_id, :start_time, :end_time, :notes)
  end
end

# db/migrate/20250101000001_create_organizations.rb
class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :domain
      t.text :description
      t.string :contact_email
      t.string :contact_phone
      t.text :address
      t.string :time_zone, default: 'UTC'
      t.jsonb :settings, default: {}
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :domain, unique: true
    add_index :organizations, :active
  end
end

# db/migrate/20250101000002_add_organization_to_users.rb
class AddOrganizationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :organization, null: false, foreign_key: true
    add_index :users, [:organization_id, :email], unique: true
  end
end

# db/migrate/20250101000003_add_organization_to_appointments.rb
class AddOrganizationToAppointments < ActiveRecord::Migration[7.0]
  def change
    add_reference :appointments, :organization, null: false, foreign_key: true
    add_index :appointments, :organization_id
  end
end

# db/migrate/20250101000004_add_organization_to_students.rb
class AddOrganizationToStudents < ActiveRecord::Migration[7.0]
  def change
    add_reference :students, :organization, null: false, foreign_key: true
    add_index :students, :organization_id
  end
end

# For Sidekiq jobs with multi-tenancy
require 'acts_as_tenant/sidekiq'

# app/workers/application_worker.rb
class ApplicationWorker
  include Sidekiq::Worker
  include ActsAsTenant::WorkerExtensions
  
  # This ensures the worker runs in the context of the correct tenant
  def perform(*args)
    # Tenant context is automatically set by acts_as_tenant
    super
  end
end

# Example: app/workers/appointment_reminder_worker.rb
class AppointmentReminderWorker < ApplicationWorker
  def perform(appointment_id)
    # Tenant context is automatically available
    appointment = Appointment.find(appointment_id)
    # Send reminder email or SMS
    AppointmentMailer.reminder(appointment).deliver_now
  end
end

# spec/support/acts_as_tenant.rb (for testing)
RSpec.configure do |config|
  config.before(:suite) do
    # Make the default tenant globally available to the tests
    $default_organization = Organization.create!(
      name: 'Test Organization',
      subdomain: 'test',
      contact_email: 'test@example.com'
    )
  end

  config.before(:each) do |example|
    if example.metadata[:type] == :request
      # Set the `test_tenant` value for integration tests
      ActsAsTenant.test_tenant = $default_organization
    else
      # Otherwise just use current_tenant
      ActsAsTenant.current_tenant = $default_organization
    end
  end

  config.after(:each) do |example|
    # Clear any tenancy that might have been set
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end
end
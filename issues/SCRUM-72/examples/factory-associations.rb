# Factory Associations for Multi-Tenant Testing
# This demonstrates proper factory setup with tenant context and association handling

# Organization Factory
FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org#{n}" }
    sequence(:email) { |n| "org#{n}@example.com" }
    phone { "555-0123" }
    address { "123 Main St" }
    city { "Example City" }
    state { "CA" }
    zip_code { "12345" }
    time_zone { "America/Los_Angeles" }
    active { true }
    
    # Ensure roles are created for the organization
    after(:create) do |organization|
      Role.create_defaults_for_organization(organization)
    end
  end
end

# User Factory with tenant context
FactoryBot.define do
  factory :user do
    organization
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:uid) { |n| "google_#{n}" }
    first_name { "John" }
    last_name { "Doe" }
    phone { "555-0456" }
    jti { SecureRandom.uuid }
    
    # Traits for different user types
    trait :admin do
      after(:create) do |user|
        ActsAsTenant.with_tenant(user.organization) do
          user.assign_role('admin')
        end
      end
    end
    
    trait :professional do
      after(:create) do |user|
        ActsAsTenant.with_tenant(user.organization) do
          user.assign_role('professional')
        end
      end
    end
    
    trait :staff do
      after(:create) do |user|
        ActsAsTenant.with_tenant(user.organization) do
          user.assign_role('staff')
        end
      end
    end
    
    trait :parent do
      after(:create) do |user|
        ActsAsTenant.with_tenant(user.organization) do
          user.assign_role('client')
        end
      end
    end
  end
end

# Professional Factory
FactoryBot.define do
  factory :professional do
    # Use association to link to user, not direct reference
    association :user, factory: [:user, :professional]
    organization { user.organization }
    
    license_number { "LIC123456" }
    specialization { "Speech Therapy" }
    experience_years { 5 }
    hourly_rate { 75.00 }
    bio { "Experienced speech therapist specializing in pediatric care." }
    active { true }
    
    # Working hours (JSON format)
    working_hours do
      {
        monday: { start: "09:00", end: "17:00" },
        tuesday: { start: "09:00", end: "17:00" },
        wednesday: { start: "09:00", end: "17:00" },
        thursday: { start: "09:00", end: "17:00" },
        friday: { start: "09:00", end: "17:00" },
        saturday: { start: "10:00", end: "14:00" },
        sunday: { start: nil, end: nil }
      }
    end
    
    trait :with_appointments do
      after(:create) do |professional|
        ActsAsTenant.with_tenant(professional.organization) do
          create_list(:appointment, 3, professional: professional)
        end
      end
    end
  end
end

# Student Factory
FactoryBot.define do
  factory :student do
    organization
    sequence(:first_name) { |n| "Student #{n}" }
    last_name { "Doe" }
    date_of_birth { 8.years.ago }
    grade_level { "2nd Grade" }
    diagnosis { "Speech Delay" }
    emergency_contact_name { "Jane Doe" }
    emergency_contact_phone { "555-0789" }
    medical_notes { "No known allergies" }
    active { true }
    
    # Parent association
    association :parent, factory: [:user, :parent]
    
    # Ensure parent belongs to same organization
    after(:build) do |student|
      student.parent.organization = student.organization
    end
    
    trait :with_appointments do
      after(:create) do |student|
        ActsAsTenant.with_tenant(student.organization) do
          create_list(:appointment, 2, student: student)
        end
      end
    end
  end
end

# Appointment Factory
FactoryBot.define do
  factory :appointment do
    organization
    association :professional, factory: :professional
    association :student, factory: :student
    
    scheduled_at { 1.day.from_now }
    duration { 60 } # minutes
    appointment_type { "therapy" }
    notes { "Regular therapy session" }
    
    # Ensure all associations belong to same organization
    after(:build) do |appointment|
      appointment.professional.organization = appointment.organization
      appointment.student.organization = appointment.organization
    end
    
    # Different state traits
    trait :draft do
      state { "draft" }
    end
    
    trait :pre_confirmed do
      state { "pre_confirmed" }
      expires_at { 24.hours.from_now }
    end
    
    trait :confirmed do
      state { "confirmed" }
      confirmed_at { Time.current }
    end
    
    trait :executed do
      state { "executed" }
      executed_at { 1.hour.ago }
      confirmed_at { 1.day.ago }
    end
    
    trait :cancelled do
      state { "cancelled" }
      cancelled_at { 1.hour.ago }
      cancellation_reason { "Rescheduled" }
    end
    
    trait :past do
      scheduled_at { 1.week.ago }
    end
    
    trait :upcoming do
      scheduled_at { 1.week.from_now }
    end
  end
end

# Test helper for creating objects with tenant context
module TenantTestHelper
  def create_with_tenant(organization, *args)
    ActsAsTenant.with_tenant(organization) do
      create(*args)
    end
  end
  
  def build_with_tenant(organization, *args)
    ActsAsTenant.with_tenant(organization) do
      build(*args)
    end
  end
end

# Include in RSpec
RSpec.configure do |config|
  config.include TenantTestHelper
end
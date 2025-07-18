FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "User#{n}" }
    last_name { "Doe" }
    phone { "+1-555-0123" }
    password { "password123" }
    password_confirmation { "password123" }
    jti { SecureRandom.uuid }
    organization

    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@example.com" }
      first_name { "Admin" }
      last_name { "User" }
    end

    trait :professional do
      role { :professional }
      sequence(:email) { |n| "professional#{n}@example.com" }
      first_name { "Dr." }
      last_name { "Professional" }
    end

    trait :secretary do
      role { :staff }
      sequence(:email) { |n| "secretary#{n}@example.com" }
      first_name { "Secretary" }
      last_name { "Staff" }
    end

    trait :staff do
      role { :staff }
      sequence(:email) { |n| "staff#{n}@example.com" }
      first_name { "Staff" }
      last_name { "Member" }
    end

    trait :client do
      role { :guardian }
      sequence(:email) { |n| "client#{n}@example.com" }
      first_name { "Client" }
      last_name { "Parent" }
    end

    trait :parent do
      role { :guardian }
      sequence(:email) { |n| "parent#{n}@example.com" }
      first_name { "Parent" }
      last_name { "Guardian" }
    end
    
    trait :guardian do
      role { :guardian }
      sequence(:email) { |n| "guardian#{n}@example.com" }
      first_name { "Guardian" }
      last_name { "Parent" }
    end

    trait :with_google_auth do
      uid { SecureRandom.uuid }
    end
  end
end
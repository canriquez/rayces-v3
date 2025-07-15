FactoryBot.define do
  factory :role do
    # Default to admin role to avoid conflicts
    name { "Administrator" }
    key { "admin" }
    description { "Full system administrator with all permissions" }
    active { true }
    organization

    trait :admin do
      name { "Administrator" }
      key { "admin" }
      description { "Full system administrator with all permissions" }
    end

    trait :professional do
      name { "Professional" }
      key { "professional" }
      description { "Therapeutic professional who provides services" }
    end

    trait :secretary do
      name { "Secretary" }
      key { "secretary" }
      description { "Administrative staff member" }
    end

    trait :client do
      name { "Client" }
      key { "client" }
      description { "Parent or guardian who books appointments" }
    end

    trait :inactive do
      active { false }
    end
  end
end
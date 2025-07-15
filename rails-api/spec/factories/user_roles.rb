FactoryBot.define do
  factory :user_role do
    active { true }
    assigned_at { Time.current }

    # Create associations in the same organization
    transient do
      shared_organization { create(:organization, name: "Shared Org #{Time.now.to_i}", subdomain: "shared-#{Time.now.to_i}") }
    end

    user { create(:user, organization: shared_organization, email: "user-#{Time.now.to_i}@example.com") }
    role { shared_organization.roles.find_by(key: 'professional') || create(:role, :professional, organization: shared_organization) }
    organization { shared_organization }

    trait :admin_role do
      role { shared_organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: shared_organization) }
    end

    trait :professional_role do
      role { shared_organization.roles.find_by(key: 'professional') || create(:role, :professional, organization: shared_organization) }
    end

    trait :secretary_role do
      role { shared_organization.roles.find_by(key: 'secretary') || create(:role, :secretary, organization: shared_organization) }
    end

    trait :client_role do
      role { shared_organization.roles.find_by(key: 'client') || create(:role, :client, organization: shared_organization) }
    end

    trait :inactive do
      active { false }
      assigned_at { 1.week.ago }
    end

    trait :recent do
      assigned_at { 1.day.ago }
    end

    trait :old do
      assigned_at { 2.weeks.ago }
    end
  end
end
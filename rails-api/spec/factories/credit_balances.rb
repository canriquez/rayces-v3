FactoryBot.define do
  factory :credit_balance do
    # Create organization first to ensure tenant consistency
    transient do
      shared_organization { create(:organization) }
    end
    
    organization { shared_organization }
    user { create(:user, :guardian, organization: shared_organization) }
    balance { 100 }
    lifetime_purchased { 100 }
    lifetime_used { 0 }
    
    trait :empty do
      balance { 0 }
      lifetime_purchased { 0 }
      lifetime_used { 0 }
    end
    
    trait :with_usage do
      balance { 70 }
      lifetime_purchased { 100 }
      lifetime_used { 30 }
    end
    
    trait :large_balance do
      balance { 1000 }
      lifetime_purchased { 1000 }
      lifetime_used { 0 }
    end
  end
end
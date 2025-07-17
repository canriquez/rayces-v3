FactoryBot.define do
  factory :credit_transaction do
    # Create organization first to ensure tenant consistency
    transient do
      shared_organization { create(:organization) }
    end
    
    organization { shared_organization }
    user { create(:user, :guardian, organization: shared_organization) }
    credit_balance { create(:credit_balance, shared_organization: shared_organization, user: user) }
    amount { 50 }
    transaction_type { 'purchase' }
    status { 'pending' }
    metadata { {} }
    
    trait :completed do
      status { 'completed' }
      processed_at { Time.current }
    end
    
    trait :failed do
      status { 'failed' }
      metadata { { failure_reason: 'Payment declined' } }
    end
    
    trait :pending do
      status { 'pending' }
      processed_at { nil }
    end
    
    trait :purchase do
      transaction_type { 'purchase' }
      amount { 100 }
      payment_method { 'credit_card' }
    end
    
    trait :debit do
      transaction_type { 'appointment_debit' }
      amount { -30 }
      association :appointment
    end
    
    trait :refund do
      transaction_type { 'cancellation_refund' }
      amount { 30 }
      association :appointment
    end
    
    trait :admin_adjustment do
      transaction_type { 'admin_adjustment' }
      amount { 50 }
      metadata { { reason: 'Customer service credit' } }
    end
  end
end
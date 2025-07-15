FactoryBot.define do
  factory :appointment do
    # Create organization first to ensure tenant consistency
    transient do
      shared_organization { create(:organization) }
    end
    
    organization { shared_organization }
    professional { create(:user, :professional, organization: shared_organization) }
    client { create(:user, :guardian, organization: shared_organization) }
    student { create(:student, organization: shared_organization, parent: client) }
    scheduled_at { 1.week.from_now.change(hour: 10, minute: 0) }
    duration_minutes { 60 }
    price { 100.00 }
    state { :draft }

    trait :draft do
      state { :draft }
    end

    trait :pre_confirmed do
      state { :pre_confirmed }
      scheduled_at { 2.days.from_now.change(hour: 14, minute: 0) }
    end

    trait :confirmed do
      state { :confirmed }
      scheduled_at { 3.days.from_now.change(hour: 15, minute: 0) }
    end

    trait :executed do
      # Create with future date to pass validation, then update
      scheduled_at { 1.week.from_now.change(hour: 10, minute: 0) }
      
      after(:create) do |appointment|
        appointment.update_columns(
          scheduled_at: 1.week.ago.change(hour: 10, minute: 0),
          state: 'executed',
          notes: "Session completed successfully. Good progress observed."
        )
      end
    end

    trait :cancelled do
      state { :cancelled }
      scheduled_at { 1.week.from_now.change(hour: 11, minute: 0) }
      notes { "Cancelled due to illness. Rescheduling needed." }
    end

    trait :past do
      scheduled_at { 1.week.ago.change(hour: 9, minute: 0) }
    end

    trait :upcoming do
      scheduled_at { 1.week.from_now.change(hour: 16, minute: 0) }
    end

    trait :with_notes do
      notes { "Important session notes go here." }
    end
  end
end
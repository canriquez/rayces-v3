FactoryBot.define do
  factory :appointment do
    professional { build(:user, :professional) }
    client { build(:user, :guardian) }
    student { build(:student) }
    organization { professional.organization }
    scheduled_at { 1.week.from_now.change(hour: 10, minute: 0) }
    duration_minutes { 60 }
    price { 100.00 }
    state { :draft }

    # Ensure all associations belong to the same organization
    before(:create) do |appointment|
      appointment.client.organization = appointment.professional.organization
      appointment.student.organization = appointment.professional.organization if appointment.student
      appointment.student.parent = appointment.client if appointment.student
    end

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
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
    # Schedule for next Monday at 10am to ensure professional availability
    scheduled_at do
      # Find next Monday
      today = Date.current
      days_until_monday = (1 - today.wday) % 7
      days_until_monday = 7 if days_until_monday == 0 # If today is Monday, get next Monday
      next_monday = today + days_until_monday.days
      next_monday.to_time.change(hour: 10, min: 0)
    end
    duration_minutes { 60 }
    price { 100.00 }
    state { :draft }

    trait :draft do
      state { :draft }
    end

    trait :pre_confirmed do
      state { :pre_confirmed }
      scheduled_at do
        # Find next Tuesday at 2pm
        today = Date.current
        days_until_tuesday = (2 - today.wday) % 7
        days_until_tuesday = 7 if days_until_tuesday == 0
        next_tuesday = today + days_until_tuesday.days
        next_tuesday.to_time.change(hour: 14, min: 0)
      end
    end

    trait :confirmed do
      state { :confirmed }
      scheduled_at do
        # Find next Wednesday at 3pm
        today = Date.current
        days_until_wednesday = (3 - today.wday) % 7
        days_until_wednesday = 7 if days_until_wednesday == 0
        next_wednesday = today + days_until_wednesday.days
        next_wednesday.to_time.change(hour: 15, min: 0)
      end
    end

    trait :executed do
      # Create with future date to pass validation, then update
      scheduled_at do
        # Find next Monday at 10am
        today = Date.current
        days_until_monday = (1 - today.wday) % 7
        days_until_monday = 7 if days_until_monday == 0
        next_monday = today + days_until_monday.days
        next_monday.to_time.change(hour: 10, min: 0)
      end
      
      after(:create) do |appointment|
        appointment.update_columns(
          scheduled_at: 1.week.ago.beginning_of_week(:monday).to_time.change(hour: 10, min: 0),
          state: 'executed',
          notes: "Session completed successfully. Good progress observed."
        )
      end
    end

    trait :cancelled do
      state { :cancelled }
      scheduled_at do
        # Find next Thursday at 11am
        today = Date.current
        days_until_thursday = (4 - today.wday) % 7
        days_until_thursday = 7 if days_until_thursday == 0
        next_thursday = today + days_until_thursday.days
        next_thursday.to_time.change(hour: 11, min: 0)
      end
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
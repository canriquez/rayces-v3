FactoryBot.define do
  factory :time_slot do
    association :professional
    association :organization
    date { Date.current }
    start_time { '09:00' }
    end_time { '10:00' }
    available { true }
    
    trait :booked do
      available { false }
      association :appointment
    end
    
    trait :available do
      available { true }
      appointment { nil }
    end
    
    trait :morning do
      start_time { '08:00' }
      end_time { '09:00' }
    end
    
    trait :afternoon do
      start_time { '14:00' }
      end_time { '15:00' }
    end
    
    trait :evening do
      start_time { '18:00' }
      end_time { '19:00' }
    end
    
    trait :today do
      date { Date.current }
    end
    
    trait :tomorrow do
      date { Date.tomorrow }
    end
    
    trait :next_week do
      date { 1.week.from_now }
    end
    
    trait :past do
      date { 1.week.ago }
    end
    
    trait :long_duration do
      start_time { '09:00' }
      end_time { '11:00' }
    end
    
    trait :short_duration do
      start_time { '09:00' }
      end_time { '09:30' }
    end
    
    # Create a full day of slots
    trait :full_day do
      after(:create) do |slot|
        start_hour = 9
        end_hour = 17
        duration = 1 # hour
        
        (start_hour...end_hour).each do |hour|
          next if hour == slot.start_time.hour
          
          create(:time_slot,
            professional: slot.professional,
            organization: slot.organization,
            date: slot.date,
            start_time: "#{hour}:00",
            end_time: "#{hour + duration}:00",
            available: true
          )
        end
      end
    end
    
    # Ensure organization consistency
    before(:create) do |slot|
      if slot.professional && !slot.organization
        slot.organization = slot.professional.organization
      end
    end
  end
end
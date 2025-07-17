FactoryBot.define do
  factory :availability_rule do
    association :professional
    association :organization
    day_of_week { 1 } # Monday
    start_time { '09:00' }
    end_time { '17:00' }
    active { true }
    
    trait :morning do
      start_time { '08:00' }
      end_time { '12:00' }
    end
    
    trait :afternoon do
      start_time { '13:00' }
      end_time { '18:00' }
    end
    
    trait :evening do
      start_time { '18:00' }
      end_time { '22:00' }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :monday do
      day_of_week { 1 }
    end
    
    trait :tuesday do
      day_of_week { 2 }
    end
    
    trait :wednesday do
      day_of_week { 3 }
    end
    
    trait :thursday do
      day_of_week { 4 }
    end
    
    trait :friday do
      day_of_week { 5 }
    end
    
    trait :saturday do
      day_of_week { 6 }
    end
    
    trait :sunday do
      day_of_week { 0 }
    end
    
    # Create a full week schedule
    trait :full_week do
      after(:create) do |rule|
        (0..6).each do |day|
          next if day == rule.day_of_week
          create(:availability_rule,
            professional: rule.professional,
            organization: rule.organization,
            day_of_week: day,
            start_time: rule.start_time,
            end_time: rule.end_time,
            active: rule.active
          )
        end
      end
    end
    
    # Ensure organization consistency
    before(:create) do |rule|
      if rule.professional && !rule.organization
        rule.organization = rule.professional.organization
      end
    end
  end
end
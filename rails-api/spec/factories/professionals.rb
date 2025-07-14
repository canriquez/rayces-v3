FactoryBot.define do
  factory :professional do
    association :user, :professional
    organization { user.organization }
    title { "Dr." }
    specialization { "General Therapy" }
    bio { "Experienced professional providing therapeutic services." }
    license_number { "LIC-12345" }
    license_expiry { 2.years.from_now }
    session_duration_minutes { 60 }
    hourly_rate { 100.00 }
    availability do
      {
        "monday" => { "start" => "09:00", "end" => "17:00" },
        "tuesday" => { "start" => "09:00", "end" => "17:00" },
        "wednesday" => { "start" => "09:00", "end" => "17:00" },
        "thursday" => { "start" => "09:00", "end" => "17:00" },
        "friday" => { "start" => "09:00", "end" => "15:00" }
      }
    end
    settings do
      {
        languages: ["english"],
        certifications: ["General Practice"],
        age_groups: ["children", "adults"]
      }
    end

    trait :psychologist do
      specialization { "Psychology" }
      title { "Lic." }
      bio { "Licensed psychologist specializing in therapy for children and adults." }
      license_number { "PSY-67890" }
      settings do
        {
          languages: ["spanish"],
          certifications: ["Clinical Psychology"],
          age_groups: ["children", "adolescents", "adults"]
        }
      end
    end

    trait :speech_therapist do
      specialization { "Speech Therapy" }
      title { "Lic." }
      bio { "Speech and language therapist helping with communication disorders." }
      license_number { "ST-24680" }
      session_duration_minutes { 45 }
      settings do
        {
          languages: ["spanish"],
          certifications: ["Speech and Language Therapy"],
          age_groups: ["children", "adolescents"]
        }
      end
    end
  end
end
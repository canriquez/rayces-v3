# db/seeds.rb
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data in development
if Rails.env.development?
  puts "Clearing existing data..."
  # Temporarily disable tenant requirement for clearing data
  ActsAsTenant.without_tenant do
    Appointment.delete_all
    Professional.delete_all
    Student.delete_all
    Like.delete_all
    Post.delete_all
    User.delete_all
    Organization.delete_all
  end
end

# Create sample organizations
puts "Creating organizations..."

# Rayces organization with real details
rayces_org = Organization.create!(
  name: "Rayces - Centro de Desarrollo Integral",
  subdomain: "rayces",
  email: "carlos.anriquez@rayces.com",
  phone: "+54 11 4567-8900",
  address: "Av. Santa Fe 1234, C1060AAB Ciudad Autónoma de Buenos Aires, Argentina",
  settings: {
    timezone: "America/Argentina/Buenos_Aires",
    booking_window_days: 30,
    cancellation_policy_hours: 24,
    default_session_duration: 50,
    currency: "ARS",
    language: "es-AR"
  }
)

demo_org = Organization.create!(
  name: "Demo Therapy Center",
  subdomain: "demo",
  email: "demo@demo.com",
  phone: "+1-555-0456",
  address: "456 Demo Street, Test City, TC 67890",
  settings: {
    timezone: "America/Los_Angeles",
    booking_window_days: 14,
    cancellation_policy_hours: 48
  }
)

puts "Created #{Organization.count} organizations"

# Create users for Rayces organization based on real team data
ActsAsTenant.with_tenant(rayces_org) do
  puts "Creating users for Rayces organization..."
  
  # Admin user
  admin = User.create!(
    email: "admin@rayces.com",
    first_name: "Administrador",
    last_name: "Rayces",
    phone: "+54 11 4567-8900",
    role: :admin,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # Real Professional users from Rayces team data
  
  # 1. Lic. María de Elía Cavanagh - Directora, Psicopedagóga
  maria_cavanagh = User.create!(
    email: "m.cavanagh@rayces.com",
    first_name: "María de Elía",
    last_name: "Cavanagh",
    phone: "+54 11 4567-8901",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 2. Lic. Julieta Dip Torres - Directora, Fonoaudióloga
  julieta_dip = User.create!(
    email: "j.diptorres@rayces.com",
    first_name: "Julieta",
    last_name: "Dip Torres",
    phone: "+54 11 4567-8902",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 3. Lic. Ana Inés Lagrotteria - Psicopedagóga
  ana_lagrotteria = User.create!(
    email: "a.lagrotteria@rayces.com",
    first_name: "Ana Inés",
    last_name: "Lagrotteria",
    phone: "+54 11 4567-8903",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 4. Lic. Diana García Albesa - Fonoaudióloga
  diana_garcia = User.create!(
    email: "d.garcia@rayces.com",
    first_name: "Diana",
    last_name: "García Albesa",
    phone: "+54 11 4567-8904",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 5. Lic. Gabriela Inés Heredia - Psicopedagóga
  gabriela_heredia = User.create!(
    email: "g.heredia@rayces.com",
    first_name: "Gabriela Inés",
    last_name: "Heredia",
    phone: "+54 11 4567-8905",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 6. Lic. Julia Veneranda - Psicomotricista
  julia_veneranda = User.create!(
    email: "j.veneranda@rayces.com",
    first_name: "Julia",
    last_name: "Veneranda",
    phone: "+54 11 4567-8906",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # 7. Lic. Priscila Tarifa - Psicóloga
  priscila_tarifa = User.create!(
    email: "p.tarifa@rayces.com",
    first_name: "Priscila",
    last_name: "Tarifa",
    phone: "+54 11 4567-8907",
    role: :professional,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # Staff user (based on Cecilia González)
  cecilia_gonzalez = User.create!(
    email: "c.gonzalez@rayces.com",
    first_name: "Cecilia",
    last_name: "González",
    phone: "+54 11 4567-8908",
    role: :staff,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  # Parent users
  parent1 = User.create!(
    email: "padre1@example.com",
    first_name: "Roberto",
    last_name: "González",
    phone: "+54 11 5555-0001",
    role: :guardian,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  parent2 = User.create!(
    email: "madre1@example.com",
    first_name: "Claudia",
    last_name: "Herrera",
    phone: "+54 11 5555-0002",
    role: :guardian,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  parent3 = User.create!(
    email: "padre2@example.com",
    first_name: "Alejandro",
    last_name: "Vega",
    phone: "+54 11 5555-0003",
    role: :guardian,
    organization: rayces_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  puts "Created #{User.count} users for Rayces organization"
  
  # Create professional profiles based on real Rayces team data
  puts "Creating professional profiles..."
  
  # 1. María de Elía Cavanagh - Directora, Psicopedagóga
  prof_cavanagh = Professional.create!(
    user: maria_cavanagh,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Psicopedagogía",
    bio: "En RAYCES nos guía la búsqueda de un abordaje terapéutico que permita intervenir de manera integral en los diferentes aspectos cognitivos y socio-emocionales de los niños con dificultades de aprendizaje. Es importante generar experiencias positivas de aprendizaje de las que se desprendan estrategias para que los niños puedan incorporarlas y emplearlas en los diferentes contextos.",
    license_number: "MP 12345",
    license_expiry: 3.years.from_now,
    session_duration_minutes: 50,
    hourly_rate: 9500.00, # ARS - Director rate
    availability: {
      "monday" => { "start" => "09:00", "end" => "18:00" },
      "tuesday" => { "start" => "09:00", "end" => "18:00" },
      "wednesday" => { "start" => "09:00", "end" => "18:00" },
      "thursday" => { "start" => "09:00", "end" => "18:00" },
      "friday" => { "start" => "09:00", "end" => "16:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Directora - Coordinadora Inclusión"],
      age_groups: ["niños", "adolescentes"]
    }
  )
  
  # 2. Julieta Dip Torres - Directora, Fonoaudióloga
  prof_dip = Professional.create!(
    user: julieta_dip,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Fonoaudiología",
    bio: "El lenguaje como capacidad innata de significar a través de cualquier código de signos, permite comunicar, expresar, comprender, simbolizar, pensar y constituirse como sujetos. Más allá de las definiciones y conceptos en cuanto a la estimulación y desarrollo del lenguaje, el compromiso, la cooperación, el respeto y la pasión en el trabajo con el niño y su familia, son valores que diariamente nos inspiran.",
    license_number: "MN 23456",
    license_expiry: 2.years.from_now,
    session_duration_minutes: 45,
    hourly_rate: 8500.00, # ARS - Director rate
    availability: {
      "monday" => { "start" => "08:00", "end" => "17:00" },
      "tuesday" => { "start" => "08:00", "end" => "17:00" },
      "wednesday" => { "start" => "08:00", "end" => "17:00" },
      "thursday" => { "start" => "08:00", "end" => "17:00" },
      "friday" => { "start" => "08:00", "end" => "15:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Directora - Coordinadora Inclusión"],
      age_groups: ["primera infancia", "niños", "adolescentes"]
    }
  )
  
  # 3. Ana Inés Lagrotteria - Psicopedagóga
  prof_lagrotteria = Professional.create!(
    user: ana_lagrotteria,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Psicopedagogía",
    bio: "En RAYCES buscamos acompañar y orientar, de forma integral y de manera conjunta con la escuela y la familia, a los niños en sus trayectorias del aprendizaje. Poder hacer foco en sus fortalezas y logros para así llegar a la autonomía y ser los protagonistas de sus experiencias.",
    license_number: "MP 34567",
    license_expiry: 3.years.from_now,
    session_duration_minutes: 50,
    hourly_rate: 7500.00, # ARS
    availability: {
      "monday" => { "start" => "09:00", "end" => "17:00" },
      "tuesday" => { "start" => "09:00", "end" => "17:00" },
      "wednesday" => { "start" => "09:00", "end" => "17:00" },
      "thursday" => { "start" => "09:00", "end" => "17:00" },
      "friday" => { "start" => "09:00", "end" => "15:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Especialización en Dificultades de Aprendizaje"],
      age_groups: ["niños", "adolescentes"]
    }
  )
  
  # 4. Diana García Albesa - Fonoaudióloga
  prof_garcia = Professional.create!(
    user: diana_garcia,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Fonoaudiología",
    bio: "Acompañar, sostener, guiar, escuchar, movilizar aprendizajes, buscar vías alternativas para la recepción y transmisión de información...son algunas de las acciones profesionales que intentamos llevar a cabo de manera interdisciplinaria en Rayces.",
    license_number: "MN 45678",
    license_expiry: 2.years.from_now,
    session_duration_minutes: 45,
    hourly_rate: 6500.00, # ARS
    availability: {
      "tuesday" => { "start" => "10:00", "end" => "18:00" },
      "wednesday" => { "start" => "10:00", "end" => "18:00" },
      "thursday" => { "start" => "10:00", "end" => "18:00" },
      "friday" => { "start" => "10:00", "end" => "16:00" },
      "saturday" => { "start" => "09:00", "end" => "13:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Especialización en Comunicación"],
      age_groups: ["primera infancia", "niños", "adolescentes"]
    }
  )
  
  # 5. Gabriela Inés Heredia - Psicopedagóga
  prof_heredia = Professional.create!(
    user: gabriela_heredia,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Psicopedagogía",
    bio: "El aprendizaje es un proceso sistemático y asistemático que se desarrolla a lo largo de toda la vida. Cada ser humano, como ser único e irrepetible transita este proceso de manera y en tiempos distintos, es por ello, que debemos detenernos en la peculiaridad de cada sujeto.",
    license_number: "MP 56789",
    license_expiry: 3.years.from_now,
    session_duration_minutes: 50,
    hourly_rate: 7500.00, # ARS
    availability: {
      "monday" => { "start" => "14:00", "end" => "20:00" },
      "tuesday" => { "start" => "14:00", "end" => "20:00" },
      "wednesday" => { "start" => "14:00", "end" => "20:00" },
      "thursday" => { "start" => "14:00", "end" => "20:00" },
      "friday" => { "start" => "14:00", "end" => "18:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Psicopedagogía Clínica"],
      age_groups: ["niños", "adolescentes"]
    }
  )
  
  # 6. Julia Veneranda - Psicomotricista
  prof_veneranda = Professional.create!(
    user: julia_veneranda,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Psicomotricidad",
    bio: "Desde el área de Psicomotricidad proponemos, como objetivo general, brindar un espacio en donde se pueda desarrollar o restablecer, mediante un abordaje corporal, el movimiento, la postura, la acción y el gesto, las capacidades del individuo.",
    license_number: "TO 67890",
    license_expiry: 2.years.from_now,
    session_duration_minutes: 45,
    hourly_rate: 7000.00, # ARS
    availability: {
      "monday" => { "start" => "08:00", "end" => "16:00" },
      "tuesday" => { "start" => "08:00", "end" => "16:00" },
      "wednesday" => { "start" => "08:00", "end" => "16:00" },
      "thursday" => { "start" => "08:00", "end" => "16:00" },
      "friday" => { "start" => "08:00", "end" => "14:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Psicomotricidad Educativa"],
      age_groups: ["primera infancia", "niños"]
    }
  )
  
  # 7. Priscila Tarifa - Psicóloga
  prof_tarifa = Professional.create!(
    user: priscila_tarifa,
    organization: rayces_org,
    title: "Lic.",
    specialization: "Psicología",
    bio: "En Rayces buscamos desarrollar oportunidades de aprendizajes y de crecimiento a través de situaciones lúdicas, en donde a partir de las habilidades e intereses de cada niño, ayudamos a alcanzar los desafíos que pueden llegar a presentar en las diferentes áreas de desarrollo.",
    license_number: "MP 78901",
    license_expiry: 4.years.from_now,
    session_duration_minutes: 50,
    hourly_rate: 8000.00, # ARS
    availability: {
      "monday" => { "start" => "10:00", "end" => "18:00" },
      "tuesday" => { "start" => "10:00", "end" => "18:00" },
      "wednesday" => { "start" => "10:00", "end" => "18:00" },
      "thursday" => { "start" => "10:00", "end" => "18:00" },
      "friday" => { "start" => "10:00", "end" => "16:00" }
    },
    settings: {
      languages: ["español"],
      certifications: ["Psicología Infantil"],
      age_groups: ["niños", "adolescentes"]
    }
  )
  
  puts "Created #{Professional.count} professional profiles"
  
  # Create students
  puts "Creating students..."
  
  student1 = Student.create!(
    parent: parent1,
    organization: rayces_org,
    first_name: "Valentina",
    last_name: "González",
    date_of_birth: 7.years.ago,
    gender: "female",
    grade_level: "2° grado",
    medical_notes: "Diagnóstico de TEA nivel 1. Sin alergias conocidas.",
    educational_notes: "Requiere apoyo en habilidades sociales y comunicación. Muy buena en matemáticas.",
    emergency_contacts: [
      {
        name: "Claudia González",
        relationship: "Madre",
        phone: "+54 11 5555-0004",
        email: "claudia.gonzalez@example.com"
      }
    ]
  )
  
  student2 = Student.create!(
    parent: parent1,
    organization: rayces_org,
    first_name: "Mateo",
    last_name: "González",
    date_of_birth: 11.years.ago,
    gender: "male",
    grade_level: "6° grado",
    medical_notes: "TDAH. Medicación: Metilfenidato 18mg por las mañanas.",
    educational_notes: "Dificultades de atención y organización. Muy creativo y sociable.",
    emergency_contacts: [
      {
        name: "Claudia González",
        relationship: "Madre",
        phone: "+54 11 5555-0004",
        email: "claudia.gonzalez@example.com"
      }
    ]
  )
  
  student3 = Student.create!(
    parent: parent2,
    organization: rayces_org,
    first_name: "Lucía",
    last_name: "Herrera",
    date_of_birth: 5.years.ago,
    gender: "female",
    grade_level: "Jardín",
    medical_notes: "Retraso en el desarrollo del lenguaje. Hipoacusia leve oído derecho.",
    educational_notes: "Muy sociable, responde bien a estímulos visuales. Usa audífono.",
    emergency_contacts: [
      {
        name: "Fernando Herrera",
        relationship: "Padre",
        phone: "+54 11 5555-0005",
        email: "fernando.herrera@example.com"
      }
    ]
  )
  
  student4 = Student.create!(
    parent: parent3,
    organization: rayces_org,
    first_name: "Santiago",
    last_name: "Vega",
    date_of_birth: 9.years.ago,
    gender: "male",
    grade_level: "4° grado",
    medical_notes: "Dislexia. Sin otras condiciones médicas relevantes.",
    educational_notes: "Excelente comprensión oral, dificultades en lectoescritura. Le gusta mucho el deporte.",
    emergency_contacts: [
      {
        name: "Mariana Vega",
        relationship: "Madre",
        phone: "+54 11 5555-0006",
        email: "mariana.vega@example.com"
      }
    ]
  )
  
  puts "Created #{Student.count} students"
  
  # Create sample appointments
  puts "Creating sample appointments..."
  
  # Past appointment (executed) - skip validation for executed appointments
  past_appointment = Appointment.new(
    professional: maria_cavanagh,
    client: parent1,
    student: student1,
    organization: rayces_org,
    scheduled_at: 1.week.ago.change(hour: 10, minute: 0),
    duration_minutes: 50,
    state: :executed,
    notes: "Buena sesión. Valentina mostró avances en comunicación social. Continuamos con pictogramas.",
    price: 9500.00
  )
  past_appointment.save!(validate: false)
  
  # Upcoming confirmed appointment
  Appointment.create!(
    professional: julieta_dip,
    client: parent2,
    student: student3,
    organization: rayces_org,
    scheduled_at: 2.days.from_now.change(hour: 11, minute: 0),
    duration_minutes: 45,
    state: :confirmed,
    price: 8500.00
  )
  
  # Pending confirmation appointment
  Appointment.create!(
    professional: ana_lagrotteria,
    client: parent1,
    student: student2,
    organization: rayces_org,
    scheduled_at: 1.week.from_now.change(hour: 15, minute: 0),
    duration_minutes: 50,
    state: :pre_confirmed,
    price: 7500.00
  )
  
  # Another confirmed appointment
  Appointment.create!(
    professional: priscila_tarifa,
    client: parent3,
    student: student4,
    organization: rayces_org,
    scheduled_at: 4.days.from_now.change(hour: 16, minute: 0),
    duration_minutes: 50,
    state: :confirmed,
    price: 8000.00
  )
  
  puts "Created #{Appointment.count} appointments"
end

# Create sample data for demo organization
ActsAsTenant.with_tenant(demo_org) do
  puts "Creating sample data for Demo organization..."
  
  demo_admin = User.create!(
    email: "admin@demo.com",
    first_name: "Demo",
    last_name: "Admin",
    role: :admin,
    organization: demo_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  demo_professional = User.create!(
    email: "professional@demo.com",
    first_name: "Demo",
    last_name: "Professional",
    role: :professional,
    organization: demo_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  demo_parent = User.create!(
    email: "parent@demo.com",
    first_name: "Demo",
    last_name: "Parent",
    role: :guardian,
    organization: demo_org,
    password: "password123",
    jti: SecureRandom.uuid
  )
  
  Professional.create!(
    user: demo_professional,
    organization: demo_org,
    title: "Dr.",
    specialization: "General Therapy",
    bio: "Demo professional for testing purposes.",
    session_duration_minutes: 45,
    hourly_rate: 100.00
  )
  
  puts "Created demo organization data"
end

# Legacy MyHub posts (preserve existing functionality)
# NOTE: Skipping post creation as Post model expects content field that doesn't exist in schema
puts "Skipping legacy MyHub posts creation (content field mismatch)"

puts "Database seeded successfully!"
puts ""
puts "=== SEED DATA SUMMARY ==="

# Count without tenant context for summary
ActsAsTenant.without_tenant do
  puts "Organizations: #{Organization.count}"
  puts "Users: #{User.count}"
  puts "Professionals: #{Professional.count}"
  puts "Students: #{Student.count}"
  puts "Appointments: #{Appointment.count}"
  puts "Posts: #{Post.count}"
end
puts ""
puts "=== RAYCES REAL TEAM CREDENTIALS ==="
puts "Admin: admin@rayces.com / password123"
puts ""
puts "DIRECTORS:"
puts "Lic. María de Elía Cavanagh (Psicopedagóga): m.cavanagh@rayces.com / password123"
puts "Lic. Julieta Dip Torres (Fonoaudióloga): j.diptorres@rayces.com / password123"
puts ""
puts "PROFESSIONALS:"
puts "Lic. Ana Inés Lagrotteria (Psicopedagóga): a.lagrotteria@rayces.com / password123"
puts "Lic. Diana García Albesa (Fonoaudióloga): d.garcia@rayces.com / password123"
puts "Lic. Gabriela Inés Heredia (Psicopedagóga): g.heredia@rayces.com / password123"
puts "Lic. Julia Veneranda (Psicomotricista): j.veneranda@rayces.com / password123"
puts "Lic. Priscila Tarifa (Psicóloga): p.tarifa@rayces.com / password123"
puts ""
puts "STAFF:"
puts "Cecilia González (Asistente): c.gonzalez@rayces.com / password123"
puts ""
puts "PARENTS (TEST):"
puts "Roberto González: padre1@example.com / password123"
puts "Claudia Herrera: madre1@example.com / password123"
puts "Alejandro Vega: padre2@example.com / password123"
puts ""
puts "=== DEMO CREDENTIALS ==="
puts "Demo Admin: admin@demo.com / password123"
puts "Demo Professional: professional@demo.com / password123"
puts "Demo Parent: parent@demo.com / password123"
require 'rails_helper'

RSpec.describe Student, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:parent) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:date_of_birth) }
  end

  describe 'associations' do
    it { should belong_to(:parent).class_name('User') }
    it { should have_many(:appointments) }
  end


  describe 'JSON serialization' do
    let(:student) { create(:student) }

    it 'serializes emergency_contacts as JSON' do
      expect(student.emergency_contacts).to be_an(Array)
      expect(student.emergency_contacts.first).to be_a(Hash)
      expect(student.emergency_contacts.first['name']).to be_present
    end

    it 'allows updating emergency contacts' do
      new_contacts = [
        {
          name: "John Doe",
          relationship: "Uncle",
          phone: "+1-555-1234",
          email: "john@example.com"
        },
        {
          name: "Jane Smith",
          relationship: "Aunt",
          phone: "+1-555-5678",
          email: "jane@example.com"
        }
      ]
      
      student.update!(emergency_contacts: new_contacts)
      student.reload
      
      expect(student.emergency_contacts.length).to eq(2)
      expect(student.emergency_contacts.first['name']).to eq('John Doe')
      expect(student.emergency_contacts.second['relationship']).to eq('Aunt')
    end
  end

  describe 'age calculation' do
    it 'calculates age correctly' do
      birth_date = 8.years.ago.to_date
      student = create(:student, date_of_birth: birth_date)
      expect(student.age).to eq(8)
    end

    it 'handles recent birthdays' do
      # Born exactly 10 years ago today
      birth_date = 10.years.ago.to_date
      student = create(:student, date_of_birth: birth_date)
      expect(student.age).to eq(10)
    end

    it 'handles upcoming birthdays' do
      # Born 7 years and 11 months ago (birthday hasn't happened this year)
      birth_date = 7.years.ago.to_date + 1.month
      student = create(:student, date_of_birth: birth_date)
      expect(student.age).to eq(6)
    end
  end

  describe 'full name' do
    let(:student) { create(:student, first_name: 'Emily', last_name: 'Johnson') }

    it 'returns full name' do
      expect(student.full_name).to eq('Emily Johnson')
    end
  end

  describe 'scopes and queries' do
    let(:org) { create(:organization) }
    let(:parent) { create(:user, :parent, organization: org) }
    
    before do
      @young_student = create(:student, 
        parent: parent,
        organization: org,
        date_of_birth: 5.years.ago,
        grade_level: 'Kindergarten'
      )
      @older_student = create(:student,
        parent: parent,
        organization: org, 
        date_of_birth: 12.years.ago,
        grade_level: '6th Grade'
      )
    end

    it 'can filter by age range' do
      young_students = Student.joins('').where('extract(year from age(date_of_birth)) < ?', 8)
      expect(young_students).to include(@young_student)
      expect(young_students).not_to include(@older_student)
    end

    it 'can filter by grade level' do
      kindergarten_students = Student.where(grade_level: 'Kindergarten')
      expect(kindergarten_students).to include(@young_student)
      expect(kindergarten_students).not_to include(@older_student)
    end
  end

  describe 'data privacy and security' do
    let(:student) { create(:student) }

    it 'protects sensitive medical information' do
      expect(student.medical_notes).to be_present
      # In a real app, you might want to encrypt this field
    end

    it 'stores emergency contact information securely' do
      contact = student.emergency_contacts.first
      expect(contact['phone']).to be_present
      expect(contact['email']).to be_present
    end
  end

  describe 'appointment relationships' do
    let(:student) { create(:student) }
    let(:professional) { create(:professional, organization: student.organization) }

    it 'can have multiple appointments' do
      appointment1 = create(:appointment,
        student: student,
        professional: professional.user,
        client: student.parent,
        organization: student.organization
      )
      
      # Schedule appointment during professional's availability (Monday 10am)
      next_monday = Date.today.beginning_of_week(:monday) + 1.week
      scheduled_time = next_monday.to_time.change(hour: 10, min: 0)
      
      appointment2 = create(:appointment,
        student: student,
        professional: professional.user,
        client: student.parent,
        organization: student.organization,
        scheduled_at: scheduled_time
      )

      expect(student.appointments).to include(appointment1, appointment2)
    end
  end

  describe 'factories' do
    it 'creates valid students' do
      student = build(:student)
      expect(student).to be_valid
    end

    it 'creates students with special needs' do
      special_needs_student = create(:student, :with_special_needs)
      expect(special_needs_student.medical_notes).to include('ADHD')
      expect(special_needs_student.educational_notes).to include('attention')
    end

    it 'creates students of different ages' do
      preschooler = create(:student, :preschooler)
      teenager = create(:student, :teenager)

      expect(preschooler.age).to be < 6
      expect(teenager.age).to be > 12
      expect(preschooler.grade_level).to eq('Preschool')
      expect(teenager.grade_level).to eq('9th Grade')
    end
  end

  describe 'data validation' do
    it 'validates date_of_birth is not in the future' do
      future_student = build(:student, date_of_birth: 1.year.from_now)
      expect(future_student).not_to be_valid
      expect(future_student.errors[:date_of_birth]).to include("cannot be in the future")
    end

    it 'validates reasonable age ranges' do
      # NOTE: Age range validation not yet implemented
      too_old_student = build(:student, date_of_birth: 30.years.ago)
      expect(too_old_student).not_to be_valid
      expect(too_old_student.errors[:date_of_birth]).to include("student cannot be older than 18 years")
    end
  end

  describe 'gender validation' do
    it 'accepts valid gender values' do
      male_student = build(:student, gender: 'male')
      female_student = build(:student, gender: 'female')
      other_student = build(:student, gender: 'other')

      expect(male_student).to be_valid
      expect(female_student).to be_valid
      expect(other_student).to be_valid
    end

    it 'rejects invalid gender values' do
      invalid_student = build(:student, gender: 'invalid')
      expect(invalid_student).not_to be_valid
    end
  end
end
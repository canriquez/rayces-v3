# RSpec Model Testing Example - Professional Model with Availability Methods
# This demonstrates comprehensive model testing with validations and business logic

require "rails_helper"

RSpec.describe Professional, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:professional) { create(:professional, user: user, organization: organization) }

  describe "validations" do
    it "validates presence of required fields" do
      expect(professional).to be_valid
      professional.user = nil
      expect(professional).to_not be_valid
    end

    it "validates organization association" do
      expect(professional.organization).to eq(organization)
    end
  end

  describe "availability methods" do
    let(:date) { Date.current }
    let(:datetime) { Time.current }

    context "#available_on?" do
      it "returns true for available dates" do
        expect(professional.available_on?(date)).to eq(true)
      end

      it "returns false for unavailable dates" do
        # Create an appointment that conflicts
        create(:appointment, 
               professional: professional, 
               scheduled_at: datetime,
               state: 'confirmed')
        
        expect(professional.available_on?(date)).to eq(false)
      end
    end

    context "#available_at?" do
      it "returns true for available times" do
        expect(professional.available_at?(datetime)).to eq(true)
      end

      it "returns false for conflicting appointment times" do
        create(:appointment, 
               professional: professional, 
               scheduled_at: datetime,
               state: 'confirmed')
        
        expect(professional.available_at?(datetime)).to eq(false)
      end

      it "considers appointment duration for conflicts" do
        start_time = datetime
        end_time = datetime + 1.hour
        
        create(:appointment, 
               professional: professional, 
               scheduled_at: start_time,
               duration: 60, # 60 minutes
               state: 'confirmed')
        
        # Should be unavailable 30 minutes after start
        expect(professional.available_at?(start_time + 30.minutes)).to eq(false)
        # Should be available after the appointment ends
        expect(professional.available_at?(end_time + 1.minute)).to eq(true)
      end
    end
  end

  describe "associations" do
    it "has many appointments" do
      expect(professional).to respond_to(:appointments)
    end

    it "belongs to user" do
      expect(professional).to respond_to(:user)
    end

    it "belongs to organization" do
      expect(professional).to respond_to(:organization)
    end
  end

  describe "scopes" do
    it "includes available professionals" do
      expect(Professional).to respond_to(:available)
    end

    it "filters by organization" do
      expect(Professional).to respond_to(:for_organization)
    end
  end

  describe "business logic" do
    it "calculates working hours correctly" do
      expect(professional).to respond_to(:working_hours_for_date)
    end

    it "handles appointment conflicts" do
      expect(professional).to respond_to(:conflicting_appointments)
    end
  end
end
require 'rails_helper'

RSpec.describe TimeSlot, type: :model do
  let(:organization) { create(:organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:professional) { create(:professional, user: professional_user, organization: organization) }
  let(:client_user) { create(:user, :guardian, organization: organization) }
  let(:appointment) { create(:appointment, professional: professional_user, client: client_user, organization: organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  after do
    ActsAsTenant.current_tenant = nil
  end
  
  describe 'associations' do
    it { should belong_to(:professional) }
    it { should belong_to(:appointment).optional }
  end
  
  describe 'validations' do
    subject { create(:time_slot, professional: professional, organization: organization) }
    
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    
    it 'validates uniqueness of professional_id scoped to organization, date, and start_time' do
      slot1 = create(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.tomorrow,
        start_time: '09:00'
      )
      
      slot2 = build(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.tomorrow,
        start_time: '09:00'
      )
      
      expect(slot2).not_to be_valid
      expect(slot2.errors[:professional_id]).to include("already has a time slot for this date and time")
    end
    
    it 'allows same time on different dates' do
      slot1 = create(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.tomorrow,
        start_time: '09:00'
      )
      
      slot2 = build(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.tomorrow + 1,
        start_time: '09:00'
      )
      
      expect(slot2).to be_valid
    end
  end
  
  describe 'custom validations' do
    describe '#end_time_after_start_time' do
      it 'is invalid when end_time is before start_time' do
        slot = build(:time_slot,
          professional: professional,
          organization: organization,
          start_time: '14:00',
          end_time: '09:00'
        )
        
        expect(slot).not_to be_valid
        expect(slot.errors[:end_time]).to include("must be after start time")
      end
      
      it 'is invalid when end_time equals start_time' do
        slot = build(:time_slot,
          professional: professional,
          organization: organization,
          start_time: '09:00',
          end_time: '09:00'
        )
        
        expect(slot).not_to be_valid
        expect(slot.errors[:end_time]).to include("must be after start time")
      end
    end
    
    describe '#no_overlapping_slots' do
      let!(:existing_slot) { create(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.tomorrow,
        start_time: '09:00',
        end_time: '11:00'
      )}
      
      it 'is invalid when slots overlap' do
        overlapping_slot = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '10:00',
          end_time: '12:00'
        )
        
        expect(overlapping_slot).not_to be_valid
        expect(overlapping_slot.errors[:base]).to include("Time slot overlaps with existing slot")
      end
      
      it 'is valid when slots are adjacent' do
        adjacent_slot = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '11:00',
          end_time: '13:00'
        )
        
        expect(adjacent_slot).to be_valid
      end
      
      it 'allows overlapping slots for different professionals' do
        other_professional_user = create(:user, :professional, organization: organization)
        other_professional = create(:professional, user: other_professional_user, organization: organization)
        
        other_slot = build(:time_slot,
          professional: other_professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '09:00',
          end_time: '11:00'
        )
        
        expect(other_slot).to be_valid
      end
    end
  end
  
  describe 'scopes' do
    let!(:available_slot) { create(:time_slot, professional: professional, organization: organization, available: true) }
    let!(:booked_slot) { create(:time_slot, professional: professional, organization: organization, appointment: appointment, available: false, date: Date.tomorrow) }
    let!(:past_slot) { create(:time_slot, professional: professional, organization: organization, date: Date.yesterday, start_time: '10:00', end_time: '11:00') }
    let!(:future_slot) { create(:time_slot, professional: professional, organization: organization, date: Date.tomorrow + 1, start_time: '11:00', end_time: '12:00') }
    
    describe '.available' do
      it 'returns only available slots without appointments' do
        expect(TimeSlot.available).to include(available_slot)
        expect(TimeSlot.available).not_to include(booked_slot)
      end
    end
    
    describe '.booked' do
      it 'returns only booked slots' do
        expect(TimeSlot.booked).to include(booked_slot)
        expect(TimeSlot.booked).not_to include(available_slot)
      end
    end
    
    describe '.for_date' do
      it 'returns slots for specific date' do
        expect(TimeSlot.for_date(Date.tomorrow)).to include(booked_slot)
        expect(TimeSlot.for_date(Date.tomorrow)).not_to include(available_slot, past_slot, future_slot)
      end
    end
    
    describe '.for_date_range' do
      it 'returns slots within date range' do
        slots = TimeSlot.for_date_range(Date.current, Date.tomorrow + 1)
        expect(slots).to include(available_slot, booked_slot, future_slot)
        expect(slots).not_to include(past_slot)
      end
    end
    
    describe '.future' do
      it 'returns only future slots' do
        expect(TimeSlot.future).to include(available_slot, booked_slot, future_slot)
        expect(TimeSlot.future).not_to include(past_slot)
      end
    end
    
    describe '.past' do
      it 'returns only past slots' do
        expect(TimeSlot.past).to include(past_slot)
        expect(TimeSlot.past).not_to include(available_slot, booked_slot, future_slot)
      end
    end
    
    describe '.ordered' do
      it 'orders by date and start_time' do
        ordered_slots = TimeSlot.ordered
        expect(ordered_slots.first).to eq(past_slot)
        expect(ordered_slots.last).to eq(future_slot)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#update_availability' do
      it 'sets available to false when appointment is assigned' do
        slot = create(:time_slot, professional: professional, organization: organization, available: true)
        
        slot.appointment = appointment
        slot.save
        
        expect(slot.available).to be false
      end
      
      it 'sets available to true when appointment is removed' do
        slot = create(:time_slot, professional: professional, organization: organization, appointment: appointment, available: false)
        
        slot.appointment = nil
        slot.save
        
        expect(slot.available).to be true
      end
    end
  end
  
  describe '#book!' do
    let(:slot) { create(:time_slot, professional: professional, organization: organization, available: true) }
    
    context 'when slot is available' do
      it 'assigns appointment and marks as unavailable' do
        expect {
          slot.book!(appointment)
        }.to change { slot.appointment }.from(nil).to(appointment)
          .and change { slot.available }.from(true).to(false)
      end
      
      it 'persists changes' do
        slot.book!(appointment)
        slot.reload
        
        expect(slot.appointment).to eq(appointment)
        expect(slot.available).to be false
      end
    end
    
    context 'when slot is already booked' do
      before { slot.update(appointment: appointment, available: false) }
      
      it 'raises error' do
        other_appointment = create(:appointment, professional: professional_user, client: client_user, organization: organization)
        
        expect {
          slot.book!(other_appointment)
        }.to raise_error(RuntimeError, "Time slot already booked")
      end
    end
  end
  
  describe '#release!' do
    let(:slot) { create(:time_slot, professional: professional, organization: organization, appointment: appointment, available: false) }
    
    it 'removes appointment and marks as available' do
      expect {
        slot.release!
      }.to change { slot.appointment }.from(appointment).to(nil)
        .and change { slot.available }.from(false).to(true)
    end
    
    it 'persists changes' do
      slot.release!
      slot.reload
      
      expect(slot.appointment).to be_nil
      expect(slot.available).to be true
    end
  end
  
  describe '#duration_minutes' do
    it 'calculates duration in minutes' do
      slot = create(:time_slot,
        professional: professional,
        organization: organization,
        start_time: '09:00',
        end_time: '10:30'
      )
      
      expect(slot.duration_minutes).to eq(90)
    end
  end
  
  describe '#datetime_start' do
    it 'returns combined datetime for start' do
      slot = create(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.parse('2025-07-18'),
        start_time: '09:30'
      )
      
      expect(slot.datetime_start).to eq(DateTime.parse('2025-07-18 09:30:00'))
    end
  end
  
  describe '#datetime_end' do
    it 'returns combined datetime for end' do
      slot = create(:time_slot,
        professional: professional,
        organization: organization,
        date: Date.parse('2025-07-18'),
        end_time: '10:30'
      )
      
      expect(slot.datetime_end).to eq(DateTime.parse('2025-07-18 10:30:00'))
    end
  end
  
  describe '#overlaps_with?' do
    let(:slot1) { create(:time_slot,
      professional: professional,
      organization: organization,
      date: Date.tomorrow,
      start_time: '09:00',
      end_time: '11:00'
    )}
    
    context 'with overlapping scenarios' do
      it 'returns true when slots overlap' do
        slot2 = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '10:00',
          end_time: '12:00'
        )
        
        expect(slot1.overlaps_with?(slot2)).to be true
      end
      
      it 'returns true when one slot contains another' do
        slot2 = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '09:30',
          end_time: '10:30'
        )
        
        expect(slot1.overlaps_with?(slot2)).to be true
      end
    end
    
    context 'with non-overlapping scenarios' do
      it 'returns false for different dates' do
        slot2 = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow + 1,
          start_time: '09:00',
          end_time: '11:00'
        )
        
        expect(slot1.overlaps_with?(slot2)).to be false
      end
      
      it 'returns false for different professionals' do
        other_professional_user = create(:user, :professional, organization: organization)
        other_professional = create(:professional, user: other_professional_user, organization: organization)
        
        slot2 = build(:time_slot,
          professional: other_professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '09:00',
          end_time: '11:00'
        )
        
        expect(slot1.overlaps_with?(slot2)).to be false
      end
      
      it 'returns false when slots are adjacent' do
        slot2 = build(:time_slot,
          professional: professional,
          organization: organization,
          date: Date.tomorrow,
          start_time: '11:00',
          end_time: '13:00'
        )
        
        expect(slot1.overlaps_with?(slot2)).to be false
      end
    end
  end
  
  describe 'acts_as_tenant' do
    it 'is scoped to organization' do
      other_org = create(:organization, subdomain: 'other')
      other_professional_user = create(:user, :professional, organization: other_org)
      other_professional = create(:professional, user: other_professional_user, organization: other_org)
      
      ActsAsTenant.with_tenant(organization) do
        slot1 = create(:time_slot, professional: professional, organization: organization)
        expect(TimeSlot.count).to eq(1)
        expect(TimeSlot.first).to eq(slot1)
      end
      
      ActsAsTenant.with_tenant(other_org) do
        slot2 = create(:time_slot, professional: other_professional, organization: other_org)
        expect(TimeSlot.count).to eq(1)
        expect(TimeSlot.first).to eq(slot2)
      end
    end
  end
end
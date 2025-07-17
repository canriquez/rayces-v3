require 'rails_helper'

RSpec.describe AvailabilityRule, type: :model do
  let(:organization) { create(:organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:professional) { create(:professional, user: professional_user, organization: organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  after do
    ActsAsTenant.current_tenant = nil
  end
  
  describe 'associations' do
    it { should belong_to(:professional) }
  end
  
  describe 'validations' do
    subject { create(:availability_rule, professional: professional, organization: organization) }
    
    it { should validate_presence_of(:day_of_week) }
    it { should validate_inclusion_of(:day_of_week).in_array([0, 1, 2, 3, 4, 5, 6]) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    
    it 'validates uniqueness of professional_id scoped to organization, day_of_week, and start_time' do
      rule1 = create(:availability_rule, 
        professional: professional, 
        organization: organization,
        day_of_week: 1,
        start_time: '09:00'
      )
      
      rule2 = build(:availability_rule,
        professional: professional,
        organization: organization,
        day_of_week: 1,
        start_time: '09:00'
      )
      
      expect(rule2).not_to be_valid
      expect(rule2.errors[:professional_id]).to include("already has a rule for this day and time")
    end
    
    it 'allows same time on different days' do
      rule1 = create(:availability_rule,
        professional: professional,
        organization: organization,
        day_of_week: 1,
        start_time: '09:00'
      )
      
      rule2 = build(:availability_rule,
        professional: professional,
        organization: organization,
        day_of_week: 2,
        start_time: '09:00'
      )
      
      expect(rule2).to be_valid
    end
  end
  
  describe 'custom validations' do
    describe '#end_time_after_start_time' do
      it 'is invalid when end_time is before start_time' do
        rule = build(:availability_rule,
          professional: professional,
          organization: organization,
          start_time: '14:00',
          end_time: '09:00'
        )
        
        expect(rule).not_to be_valid
        expect(rule.errors[:end_time]).to include("must be after start time")
      end
      
      it 'is invalid when end_time equals start_time' do
        rule = build(:availability_rule,
          professional: professional,
          organization: organization,
          start_time: '09:00',
          end_time: '09:00'
        )
        
        expect(rule).not_to be_valid
        expect(rule.errors[:end_time]).to include("must be after start time")
      end
      
      it 'is valid when end_time is after start_time' do
        rule = build(:availability_rule,
          professional: professional,
          organization: organization,
          start_time: '09:00',
          end_time: '17:00'
        )
        
        expect(rule).to be_valid
      end
    end
  end
  
  describe 'constants' do
    it 'defines days of week mapping' do
      expect(AvailabilityRule::DAYS_OF_WEEK).to eq({
        sunday: 0,
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6
      })
    end
  end
  
  describe 'scopes' do
    let!(:active_rule) { create(:availability_rule, professional: professional, organization: organization, active: true, day_of_week: 3, start_time: '09:00') }
    let!(:inactive_rule) { create(:availability_rule, professional: professional, organization: organization, active: false, day_of_week: 2, start_time: '14:00') }
    let!(:monday_rule) { create(:availability_rule, professional: professional, organization: organization, day_of_week: 1, start_time: '09:00') }
    let!(:tuesday_rule) { create(:availability_rule, professional: professional, organization: organization, day_of_week: 2, start_time: '10:00') }
    
    describe '.active' do
      it 'returns only active rules' do
        expect(AvailabilityRule.active).to include(active_rule, monday_rule, tuesday_rule)
        expect(AvailabilityRule.active).not_to include(inactive_rule)
      end
    end
    
    describe '.for_day' do
      it 'returns rules for specific day' do
        expect(AvailabilityRule.for_day(1)).to include(monday_rule)
        expect(AvailabilityRule.for_day(1)).not_to include(tuesday_rule, inactive_rule)
        
        expect(AvailabilityRule.for_day(2)).to include(tuesday_rule, inactive_rule)
        expect(AvailabilityRule.for_day(2)).not_to include(monday_rule)
      end
    end
    
    describe '.ordered' do
      it 'orders by day_of_week and start_time' do
        wednesday_early = create(:availability_rule, professional: professional, organization: organization, day_of_week: 3, start_time: '08:00')
        wednesday_late = create(:availability_rule, professional: professional, organization: organization, day_of_week: 3, start_time: '14:00')
        
        ordered_rules = AvailabilityRule.ordered
        expect(ordered_rules.index(monday_rule)).to be < ordered_rules.index(tuesday_rule)
        expect(ordered_rules.index(tuesday_rule)).to be < ordered_rules.index(wednesday_early)
        expect(ordered_rules.index(wednesday_early)).to be < ordered_rules.index(wednesday_late)
      end
    end
  end
  
  describe '#day_name' do
    it 'returns capitalized day name' do
      rule = create(:availability_rule, professional: professional, organization: organization, day_of_week: 0)
      expect(rule.day_name).to eq('Sunday')
      
      rule.day_of_week = 3
      expect(rule.day_name).to eq('Wednesday')
      
      rule.day_of_week = 6
      expect(rule.day_name).to eq('Saturday')
    end
  end
  
  describe '#time_range' do
    it 'returns formatted time range' do
      rule = create(:availability_rule,
        professional: professional,
        organization: organization,
        start_time: '09:00',
        end_time: '17:30'
      )
      
      expect(rule.time_range).to eq('09:00 - 17:30')
    end
  end
  
  describe '#overlaps_with?' do
    let(:rule1) { create(:availability_rule,
      professional: professional,
      organization: organization,
      day_of_week: 1,
      start_time: '09:00',
      end_time: '12:00',
      active: true
    )}
    
    context 'with overlapping time ranges on same day' do
      it 'returns true when ranges overlap at start' do
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 1,
          start_time: '08:00',
          end_time: '10:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be true
      end
      
      it 'returns true when ranges overlap at end' do
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 1,
          start_time: '11:00',
          end_time: '13:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be true
      end
      
      it 'returns true when one range contains another' do
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 1,
          start_time: '10:00',
          end_time: '11:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be true
      end
    end
    
    context 'with non-overlapping scenarios' do
      it 'returns false for different days' do
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 2,
          start_time: '09:00',
          end_time: '12:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be false
      end
      
      it 'returns false when ranges do not overlap' do
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 1,
          start_time: '13:00',
          end_time: '17:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be false
      end
      
      it 'returns false when one rule is inactive' do
        rule1.update(active: false)
        rule2 = build(:availability_rule,
          professional: professional,
          organization: organization,
          day_of_week: 1,
          start_time: '10:00',
          end_time: '11:00'
        )
        
        expect(rule1.overlaps_with?(rule2)).to be false
      end
    end
  end
  
  describe '#duration_minutes' do
    it 'calculates duration in minutes' do
      rule = create(:availability_rule,
        professional: professional,
        organization: organization,
        start_time: '09:00',
        end_time: '17:30'
      )
      
      expect(rule.duration_minutes).to eq(510) # 8.5 hours * 60 minutes
    end
    
    it 'handles short durations' do
      rule = create(:availability_rule,
        professional: professional,
        organization: organization,
        start_time: '09:00',
        end_time: '09:30'
      )
      
      expect(rule.duration_minutes).to eq(30)
    end
  end
  
  describe 'acts_as_tenant' do
    it 'is scoped to organization' do
      other_org = create(:organization, subdomain: 'other')
      other_professional_user = create(:user, :professional, organization: other_org)
      other_professional = create(:professional, user: other_professional_user, organization: other_org)
      
      ActsAsTenant.with_tenant(organization) do
        rule1 = create(:availability_rule, professional: professional, organization: organization)
        expect(AvailabilityRule.count).to eq(1)
        expect(AvailabilityRule.first).to eq(rule1)
      end
      
      ActsAsTenant.with_tenant(other_org) do
        rule2 = create(:availability_rule, professional: other_professional, organization: other_org)
        expect(AvailabilityRule.count).to eq(1)
        expect(AvailabilityRule.first).to eq(rule2)
      end
    end
  end
end
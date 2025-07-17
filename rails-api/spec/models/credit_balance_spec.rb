require 'rails_helper'

RSpec.describe CreditBalance, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  after do
    ActsAsTenant.current_tenant = nil
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:credit_transactions).dependent(:restrict_with_error) }
  end
  
  describe 'validations' do
    subject { create(:credit_balance, shared_organization: organization) }
    
    it { should validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:lifetime_purchased).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:lifetime_used).is_greater_than_or_equal_to(0) }
    it 'validates uniqueness of user_id within organization' do
      balance1 = create(:credit_balance, shared_organization: organization)
      balance2 = build(:credit_balance, user: balance1.user, organization: organization)
      
      expect(balance2).not_to be_valid
      expect(balance2.errors[:user_id]).to include("has already been taken")
    end
  end
  
  describe 'acts_as_tenant' do
    it 'is scoped to organization' do
      other_org = create(:organization, subdomain: 'other')
      
      ActsAsTenant.with_tenant(organization) do
        balance1 = create(:credit_balance, shared_organization: organization)
        expect(CreditBalance.count).to eq(1)
        expect(CreditBalance.first).to eq(balance1)
      end
      
      ActsAsTenant.with_tenant(other_org) do
        balance2 = create(:credit_balance, shared_organization: other_org)
        expect(CreditBalance.count).to eq(1)
        expect(CreditBalance.first).to eq(balance2)
      end
    end
  end
  
  describe '#add_credits' do
    let(:credit_balance) { create(:credit_balance, shared_organization: organization, balance: 100) }
    
    context 'when adding positive amount (purchase)' do
      it 'increases balance' do
        expect {
          credit_balance.add_credits(50, 'purchase')
        }.to change { credit_balance.reload.balance }.by(50)
      end
      
      it 'increases lifetime_purchased' do
        expect {
          credit_balance.add_credits(50, 'purchase')
        }.to change { credit_balance.reload.lifetime_purchased }.by(50)
      end
      
      it 'does not change lifetime_used' do
        expect {
          credit_balance.add_credits(50, 'purchase')
        }.not_to change { credit_balance.reload.lifetime_used }
      end
      
      it 'creates a credit transaction' do
        expect {
          credit_balance.add_credits(50, 'purchase', { payment_method: 'credit_card' })
        }.to change { credit_balance.credit_transactions.count }.by(1)
        
        transaction = credit_balance.credit_transactions.last
        expect(transaction.amount).to eq(50)
        expect(transaction.transaction_type).to eq('purchase')
        expect(transaction.status).to eq('completed')
        expect(transaction.metadata['payment_method']).to eq('credit_card')
      end
    end
    
    context 'when adding negative amount (debit)' do
      it 'decreases balance' do
        expect {
          credit_balance.add_credits(-30, 'appointment_debit')
        }.to change { credit_balance.reload.balance }.by(-30)
      end
      
      it 'increases lifetime_used' do
        expect {
          credit_balance.add_credits(-30, 'appointment_debit')
        }.to change { credit_balance.reload.lifetime_used }.by(30)
      end
      
      it 'does not change lifetime_purchased' do
        expect {
          credit_balance.add_credits(-30, 'appointment_debit')
        }.not_to change { credit_balance.reload.lifetime_purchased }
      end
    end
    
    context 'when transaction fails' do
      it 'rolls back all changes' do
        allow_any_instance_of(CreditTransaction).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        
        expect {
          expect {
            credit_balance.add_credits(50, 'purchase')
          }.to raise_error(ActiveRecord::RecordInvalid)
        }.not_to change { credit_balance.reload.balance }
      end
    end
  end
  
  describe '#deduct_credits' do
    let(:credit_balance) { create(:credit_balance, shared_organization: organization, balance: 100) }
    let(:appointment) { create(:appointment, shared_organization: organization) }
    
    context 'with sufficient balance' do
      it 'deducts credits successfully' do
        expect {
          credit_balance.deduct_credits(30, appointment)
        }.to change { credit_balance.reload.balance }.by(-30)
      end
      
      it 'creates appointment_debit transaction' do
        credit_balance.deduct_credits(30, appointment)
        
        transaction = credit_balance.credit_transactions.last
        expect(transaction.transaction_type).to eq('appointment_debit')
        expect(transaction.amount).to eq(-30)
        expect(transaction.metadata['appointment_id']).to eq(appointment.id)
      end
    end
    
    context 'with insufficient balance' do
      it 'raises InsufficientCreditsError' do
        expect {
          credit_balance.deduct_credits(150, appointment)
        }.to raise_error(CreditBalance::InsufficientCreditsError, "Insufficient credits")
      end
      
      it 'does not change balance' do
        expect {
          begin
            credit_balance.deduct_credits(150, appointment)
          rescue CreditBalance::InsufficientCreditsError
          end
        }.not_to change { credit_balance.reload.balance }
      end
    end
    
    context 'with invalid amount' do
      it 'raises ArgumentError for negative amount' do
        expect {
          credit_balance.deduct_credits(-10, appointment)
        }.to raise_error(ArgumentError, "Amount must be positive")
      end
      
      it 'raises ArgumentError for zero amount' do
        expect {
          credit_balance.deduct_credits(0, appointment)
        }.to raise_error(ArgumentError, "Amount must be positive")
      end
    end
  end
  
  describe '#refund_credits' do
    let(:credit_balance) { create(:credit_balance, shared_organization: organization, balance: 50) }
    let(:appointment) { create(:appointment, shared_organization: organization) }
    
    it 'increases balance' do
      expect {
        credit_balance.refund_credits(30, appointment)
      }.to change { credit_balance.reload.balance }.by(30)
    end
    
    it 'creates cancellation_refund transaction' do
      credit_balance.refund_credits(30, appointment)
      
      transaction = credit_balance.credit_transactions.last
      expect(transaction.transaction_type).to eq('cancellation_refund')
      expect(transaction.amount).to eq(30)
      expect(transaction.metadata['appointment_id']).to eq(appointment.id)
    end
    
    it 'raises ArgumentError for negative amount' do
      expect {
        credit_balance.refund_credits(-10, appointment)
      }.to raise_error(ArgumentError, "Amount must be positive")
    end
  end
end
require 'rails_helper'

RSpec.describe CreditTransaction, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:credit_balance) { create(:credit_balance, user: user, organization: organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  after do
    ActsAsTenant.current_tenant = nil
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:credit_balance) }
    it { should belong_to(:appointment).optional }
  end
  
  describe 'validations' do
    subject { create(:credit_transaction, shared_organization: organization) }
    
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_other_than(0) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_inclusion_of(:transaction_type).in_array(CreditTransaction::TRANSACTION_TYPES) }
    # Status has a default value, so we don't validate presence
    # it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(CreditTransaction::STATUSES) }
  end
  
  describe 'constants' do
    it 'defines transaction types' do
      expect(CreditTransaction::TRANSACTION_TYPES).to eq(%w[purchase cancellation_refund appointment_debit admin_adjustment])
    end
    
    it 'defines statuses' do
      expect(CreditTransaction::STATUSES).to eq(%w[pending completed failed])
    end
  end
  
  describe 'scopes' do
    let(:shared_user) { create(:user, :guardian, organization: organization) }
    let(:shared_balance) { create(:credit_balance, shared_organization: organization, user: shared_user) }
    let!(:completed_transaction) { create(:credit_transaction, :completed, shared_organization: organization, user: shared_user, credit_balance: shared_balance) }
    let!(:pending_transaction) { create(:credit_transaction, :pending, shared_organization: organization, user: shared_user, credit_balance: shared_balance) }
    let!(:purchase_transaction) { create(:credit_transaction, :purchase, shared_organization: organization, user: shared_user, credit_balance: shared_balance) }
    let!(:debit_transaction) { create(:credit_transaction, :debit, shared_organization: organization, user: shared_user, credit_balance: shared_balance) }
    let!(:refund_transaction) { create(:credit_transaction, :refund, shared_organization: organization, user: shared_user, credit_balance: shared_balance) }
    
    describe '.completed' do
      it 'returns only completed transactions' do
        expect(CreditTransaction.completed).to include(completed_transaction)
        expect(CreditTransaction.completed).not_to include(pending_transaction)
      end
    end
    
    describe '.pending' do
      it 'returns only pending transactions' do
        expect(CreditTransaction.pending).to include(pending_transaction)
        expect(CreditTransaction.pending).not_to include(completed_transaction)
      end
    end
    
    describe '.purchases' do
      it 'returns only purchase transactions' do
        expect(CreditTransaction.purchases).to include(purchase_transaction)
        expect(CreditTransaction.purchases).not_to include(debit_transaction, refund_transaction)
      end
    end
    
    describe '.debits' do
      it 'returns only debit transactions' do
        expect(CreditTransaction.debits).to include(debit_transaction)
        expect(CreditTransaction.debits).not_to include(purchase_transaction, refund_transaction)
      end
    end
    
    describe '.refunds' do
      it 'returns only refund transactions' do
        expect(CreditTransaction.refunds).to include(refund_transaction)
        expect(CreditTransaction.refunds).not_to include(purchase_transaction, debit_transaction)
      end
    end
  end
  
  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets default status to pending' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        
        # Create transaction with explicit nil status to test callback
        transaction = test_balance.credit_transactions.build(
          user: test_user,
          amount: 100,
          transaction_type: 'purchase'
        )
        # Force status to nil to test the callback
        transaction.send(:write_attribute, :status, nil)
        
        expect(transaction.read_attribute(:status)).to be_nil
        transaction.valid?
        expect(transaction.status).to eq('pending')
      end
      
      it 'does not override existing status' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = CreditTransaction.new(
          user: test_user,
          credit_balance: test_balance,
          organization: organization,
          amount: 100,
          transaction_type: 'purchase',
          status: 'completed'
        )
        
        transaction.valid?
        expect(transaction.status).to eq('completed')
      end
    end
  end
  
  describe '#complete!' do
    let(:test_user) { create(:user, :guardian, organization: organization) }
    let(:test_balance) { create(:credit_balance, shared_organization: organization, user: test_user) }
    let(:transaction) { create(:credit_transaction, :pending, shared_organization: organization, user: test_user, credit_balance: test_balance) }
    
    it 'changes status to completed' do
      expect {
        transaction.complete!
      }.to change { transaction.status }.from('pending').to('completed')
    end
    
    it 'sets processed_at timestamp' do
      expect(transaction.processed_at).to be_nil
      transaction.complete!
      expect(transaction.processed_at).to be_within(1.second).of(Time.current)
    end
    
    it 'persists changes' do
      transaction.complete!
      transaction.reload
      expect(transaction.status).to eq('completed')
      expect(transaction.processed_at).to be_present
    end
  end
  
  describe '#fail!' do
    let(:test_user) { create(:user, :guardian, organization: organization) }
    let(:test_balance) { create(:credit_balance, shared_organization: organization, user: test_user) }
    let(:transaction) { create(:credit_transaction, :pending, shared_organization: organization, user: test_user, credit_balance: test_balance) }
    
    it 'changes status to failed' do
      expect {
        transaction.fail!
      }.to change { transaction.status }.from('pending').to('failed')
    end
    
    it 'adds failure reason to metadata' do
      transaction.fail!('Insufficient funds')
      expect(transaction.metadata['failure_reason']).to eq('Insufficient funds')
    end
    
    it 'preserves existing metadata' do
      transaction.update(metadata: { 'original_key' => 'value' })
      transaction.fail!('Payment declined')
      
      expect(transaction.metadata['original_key']).to eq('value')
      expect(transaction.metadata['failure_reason']).to eq('Payment declined')
    end
  end
  
  describe 'type check methods' do
    describe '#purchase?' do
      it 'returns true for purchase transactions' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :purchase, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.purchase?).to be true
      end
      
      it 'returns false for other transaction types' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :debit, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.purchase?).to be false
      end
    end
    
    describe '#debit?' do
      it 'returns true for appointment_debit transactions' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :debit, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.debit?).to be true
      end
      
      it 'returns false for other transaction types' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :purchase, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.debit?).to be false
      end
    end
    
    describe '#refund?' do
      it 'returns true for cancellation_refund transactions' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :refund, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.refund?).to be true
      end
      
      it 'returns false for other transaction types' do
        test_user = create(:user, :guardian, organization: organization)
        test_balance = create(:credit_balance, shared_organization: organization, user: test_user)
        transaction = create(:credit_transaction, :purchase, shared_organization: organization, user: test_user, credit_balance: test_balance)
        expect(transaction.refund?).to be false
      end
    end
  end
  
  describe 'acts_as_tenant' do
    it 'is scoped to organization' do
      other_org = create(:organization, subdomain: 'other')
      other_user = create(:user, organization: other_org)
      other_balance = create(:credit_balance, user: other_user, organization: other_org)
      
      ActsAsTenant.with_tenant(organization) do
        transaction1 = create(:credit_transaction, user: user, credit_balance: credit_balance, organization: organization)
        expect(CreditTransaction.count).to eq(1)
        expect(CreditTransaction.first).to eq(transaction1)
      end
      
      ActsAsTenant.with_tenant(other_org) do
        transaction2 = create(:credit_transaction, user: other_user, credit_balance: other_balance, organization: other_org)
        expect(CreditTransaction.count).to eq(1)
        expect(CreditTransaction.first).to eq(transaction2)
      end
    end
  end
end
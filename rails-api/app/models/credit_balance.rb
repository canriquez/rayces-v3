class CreditBalance < ApplicationRecord
  acts_as_tenant(:organization)
  
  belongs_to :user
  has_many :credit_transactions, dependent: :restrict_with_error
  
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :lifetime_purchased, numericality: { greater_than_or_equal_to: 0 }
  validates :lifetime_used, numericality: { greater_than_or_equal_to: 0 }
  validates_uniqueness_to_tenant :user_id
  
  def add_credits(amount, transaction_type, metadata = {})
    transaction do
      credit_transactions.create!(
        amount: amount,
        transaction_type: transaction_type,
        status: 'completed',
        processed_at: Time.current,
        metadata: metadata,
        user: user
      )
      
      self.balance += amount
      self.lifetime_purchased += amount if amount > 0
      self.lifetime_used += amount.abs if amount < 0
      save!
    end
  end
  
  def deduct_credits(amount, appointment = nil, metadata = {})
    raise ArgumentError, "Amount must be positive" unless amount > 0
    raise InsufficientCreditsError, "Insufficient credits" if balance < amount
    
    add_credits(-amount, 'appointment_debit', metadata.merge(appointment_id: appointment&.id))
  end
  
  def refund_credits(amount, appointment = nil, metadata = {})
    raise ArgumentError, "Amount must be positive" unless amount > 0
    
    add_credits(amount, 'cancellation_refund', metadata.merge(appointment_id: appointment&.id))
  end
  
  class InsufficientCreditsError < StandardError; end
end
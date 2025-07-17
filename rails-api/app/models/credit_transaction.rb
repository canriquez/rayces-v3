class CreditTransaction < ApplicationRecord
  acts_as_tenant(:organization)
  
  belongs_to :user
  belongs_to :credit_balance
  belongs_to :appointment, optional: true
  
  TRANSACTION_TYPES = %w[purchase cancellation_refund appointment_debit admin_adjustment].freeze
  STATUSES = %w[pending completed failed].freeze
  
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :purchases, -> { where(transaction_type: 'purchase') }
  scope :debits, -> { where(transaction_type: 'appointment_debit') }
  scope :refunds, -> { where(transaction_type: 'cancellation_refund') }
  
  before_validation :set_default_status
  
  def complete!
    transaction do
      self.status = 'completed'
      self.processed_at = Time.current
      save!
    end
  end
  
  def fail!(reason = nil)
    transaction do
      self.status = 'failed'
      self.metadata = (metadata || {}).merge(failure_reason: reason) if reason
      save!
    end
  end
  
  def purchase?
    transaction_type == 'purchase'
  end
  
  def debit?
    transaction_type == 'appointment_debit'
  end
  
  def refund?
    transaction_type == 'cancellation_refund'
  end
  
  private
  
  def set_default_status
    self.status ||= 'pending'
  end
end
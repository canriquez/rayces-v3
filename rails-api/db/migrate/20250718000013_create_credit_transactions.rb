class CreateCreditTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_transactions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :credit_balance, null: false, foreign_key: true
      t.references :appointment, foreign_key: true
      
      t.integer :amount, null: false
      t.string :transaction_type, null: false
      t.string :status, default: 'pending', null: false
      t.jsonb :metadata, default: {}
      
      # Payment tracking
      t.string :payment_method
      t.string :payment_reference
      t.datetime :processed_at
      
      t.timestamps
    end
    
    # Performance indexes
    add_index :credit_transactions, [:organization_id, :user_id, :created_at], 
              name: 'idx_credit_trans_org_user_date'
    add_index :credit_transactions, [:organization_id, :status],
              name: 'idx_credit_trans_org_status'
    add_index :credit_transactions, :payment_reference,
              name: 'idx_credit_trans_payment_ref'
              
    # Check constraint for transaction types
    add_check_constraint :credit_transactions, 
                        "transaction_type IN ('purchase', 'cancellation_refund', 'appointment_debit', 'admin_adjustment')",
                        name: 'chk_valid_transaction_type'
  end
end
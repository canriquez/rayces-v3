class CreateCreditBalances < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_balances do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :balance, default: 0, null: false
      t.integer :lifetime_purchased, default: 0, null: false
      t.integer :lifetime_used, default: 0, null: false
      
      t.timestamps
    end
    
    # Unique constraint per user per organization
    add_index :credit_balances, [:organization_id, :user_id], unique: true, name: 'idx_unique_user_credit_balance'
    
    # Performance index for queries
    add_index :credit_balances, [:organization_id, :balance], name: 'idx_org_balance_lookup'
  end
end
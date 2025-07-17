class AddMissingFieldsToTables < ActiveRecord::Migration[7.1]
  def change
    # Add missing fields to users (first_name, last_name, phone already exist based on earlier check)
    # No changes needed for users table
    
    # Add missing fields to appointments
    change_table :appointments do |t|
      t.datetime :confirmed_at unless column_exists?(:appointments, :confirmed_at)
      t.datetime :executed_at unless column_exists?(:appointments, :executed_at)
      t.text :professional_notes unless column_exists?(:appointments, :professional_notes)
      t.boolean :uses_credit, default: false unless column_exists?(:appointments, :uses_credit)
    end
    
    # Add missing fields to professionals
    change_table :professionals do |t|
      t.jsonb :weekly_schedule, default: {} unless column_exists?(:professionals, :weekly_schedule)
      t.jsonb :blocked_dates, default: [] unless column_exists?(:professionals, :blocked_dates)
      t.integer :buffer_minutes, default: 15 unless column_exists?(:professionals, :buffer_minutes)
      t.boolean :accepts_new_clients, default: true unless column_exists?(:professionals, :accepts_new_clients)
      t.integer :session_price_cents unless column_exists?(:professionals, :session_price_cents)
      t.string :currency, default: 'ARS' unless column_exists?(:professionals, :currency)
    end
    
    # Add missing indexes
    add_index :users, [:organization_id, :role] unless index_exists?(:users, [:organization_id, :role])
    add_index :professionals, [:organization_id, :specialization] unless index_exists?(:professionals, [:organization_id, :specialization])
  end
end
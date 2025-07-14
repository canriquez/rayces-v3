class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: { to_table: :users }
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :student, null: true, foreign_key: true
      
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, default: 60, null: false
      t.string :state, null: false, default: 'draft'
      
      t.text :notes
      t.text :cancellation_reason
      t.datetime :cancelled_at
      t.integer :cancelled_by_id
      
      t.decimal :price, precision: 10, scale: 2
      t.boolean :uses_credits, default: false
      t.integer :credits_used
      
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :appointments, :state
    add_index :appointments, :scheduled_at
    add_index :appointments, [:organization_id, :scheduled_at]
    add_index :appointments, [:professional_id, :scheduled_at]
    add_index :appointments, [:client_id, :scheduled_at]
    add_index :appointments, [:organization_id, :state]
  end
end
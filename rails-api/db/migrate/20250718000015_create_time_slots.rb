class CreateTimeSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :time_slots do |t|
      t.references :professional, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :appointment, foreign_key: true
      
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :available, default: true, null: false
      
      t.timestamps
    end
    
    # Prevent double booking
    add_index :time_slots, [:professional_id, :date, :start_time],
              unique: true,
              name: 'idx_unique_time_slot'
              
    # Performance indexes
    add_index :time_slots, [:professional_id, :date, :available],
              name: 'idx_available_slots'
    add_index :time_slots, [:organization_id, :date],
              name: 'idx_org_date_slots'
  end
end
class CreateAvailabilityRules < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_rules do |t|
      t.references :professional, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      
      t.integer :day_of_week, null: false # 0-6 (Sunday-Saturday)
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end
    
    # Composite index for availability lookups
    add_index :availability_rules, [:professional_id, :day_of_week, :active],
              name: 'idx_availability_lookup'
    add_index :availability_rules, [:organization_id, :active],
              name: 'idx_org_availability'
              
    # Ensure valid day of week
    add_check_constraint :availability_rules,
                        "day_of_week >= 0 AND day_of_week <= 6",
                        name: 'chk_valid_day_of_week'
  end
end
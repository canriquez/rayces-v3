class CreateProfessionals < ActiveRecord::Migration[7.1]
  def change
    create_table :professionals do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      t.string :title
      t.string :specialization
      t.text :bio
      t.string :license_number
      t.date :license_expiry
      
      t.jsonb :availability, default: {}
      t.integer :session_duration_minutes, default: 60
      t.decimal :hourly_rate, precision: 10, scale: 2
      
      t.boolean :active, default: true
      t.jsonb :settings, default: {}
      
      t.timestamps
    end
    
    add_index :professionals, [:organization_id, :user_id], unique: true
    add_index :professionals, :active
    add_index :professionals, :specialization
  end
end
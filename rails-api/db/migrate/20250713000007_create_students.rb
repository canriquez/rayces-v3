class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :parent, null: false, foreign_key: { to_table: :users }
      
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth
      t.string :gender
      t.string :grade_level
      
      t.text :medical_notes
      t.text :educational_notes
      t.jsonb :emergency_contacts, default: []
      
      t.boolean :active, default: true
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :students, [:organization_id, :parent_id]
    add_index :students, :active
    add_index :students, [:first_name, :last_name]
  end
end
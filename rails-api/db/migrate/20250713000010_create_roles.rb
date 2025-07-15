class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.references :organization, null: false, foreign_key: true
      
      t.timestamps
    end
    
    # Composite index for tenant scoping - organization_id first for performance
    add_index :roles, [:organization_id, :key], unique: true, name: 'index_roles_on_organization_and_key'
    add_index :roles, :active
  end
end
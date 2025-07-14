class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.boolean :active, default: true, null: false
      t.jsonb :settings, default: {}
      t.string :phone
      t.string :email
      t.text :address
      
      t.timestamps
    end
    
    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :name
    add_index :organizations, :active
  end
end
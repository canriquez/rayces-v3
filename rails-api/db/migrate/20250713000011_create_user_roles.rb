class CreateUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      t.datetime :assigned_at, default: -> { 'CURRENT_TIMESTAMP' }
      
      t.timestamps
    end
    
    # Composite unique index to prevent duplicate role assignments
    add_index :user_roles, [:user_id, :role_id, :organization_id], 
              unique: true, 
              name: 'index_user_roles_on_user_role_org'
    
    # Performance indexes for common queries
    add_index :user_roles, [:organization_id, :user_id], name: 'index_user_roles_on_org_user'
    add_index :user_roles, [:organization_id, :role_id], name: 'index_user_roles_on_org_role'
    add_index :user_roles, :active
    add_index :user_roles, :assigned_at
  end
end
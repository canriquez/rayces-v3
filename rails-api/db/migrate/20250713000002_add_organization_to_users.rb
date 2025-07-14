class AddOrganizationToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :organization, null: true, foreign_key: true
    add_column :users, :role, :integer, default: 3, null: false # Default to parent role
    
    add_index :users, [:organization_id, :email], unique: true
    add_index :users, :role
    
    # In a real production environment, you'd need to handle existing data
    # For development, we'll set a default organization for existing users
    reversible do |dir|
      dir.up do
        # Create a default organization for existing users if any exist
        if connection.select_value("SELECT COUNT(*) FROM users") > 0
          org_id = connection.insert(connection.insert_sql(
            "INSERT INTO organizations (name, subdomain, email, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            ["Default Organization", "default", "admin@default.com", Time.current, Time.current]
          ))
          connection.execute("UPDATE users SET organization_id = #{org_id}")
        end
        
        # Now make organization_id required
        change_column_null :users, :organization_id, false
      end
    end
  end
end
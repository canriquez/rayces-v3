class AddOrganizationToPosts < ActiveRecord::Migration[7.1]
  def change
    # First add user_id if it doesn't exist (posts were originally content-only)
    unless column_exists?(:posts, :user_id)
      add_reference :posts, :user, null: true, foreign_key: true
    end
    
    add_reference :posts, :organization, null: true, foreign_key: true
    
    add_index :posts, [:organization_id, :created_at]
    
    # Set organization_id - if there are existing posts without users, assign to first admin
    reversible do |dir|
      dir.up do
        # First, assign posts without users to the first admin user of the first organization
        if connection.select_value("SELECT COUNT(*) FROM posts WHERE user_id IS NULL") > 0
          first_admin = connection.select_one("SELECT id, organization_id FROM users WHERE role = 0 ORDER BY id LIMIT 1")
          if first_admin
            connection.execute("UPDATE posts SET user_id = #{first_admin['id']}, organization_id = #{first_admin['organization_id']} WHERE user_id IS NULL")
          end
        end
        
        # Set organization_id based on user's organization for remaining posts
        connection.execute(<<-SQL)
          UPDATE posts 
          SET organization_id = users.organization_id
          FROM users
          WHERE posts.user_id = users.id AND posts.organization_id IS NULL
        SQL
        
        # Now make both user_id and organization_id required
        change_column_null :posts, :user_id, false
        change_column_null :posts, :organization_id, false
      end
    end
  end
end
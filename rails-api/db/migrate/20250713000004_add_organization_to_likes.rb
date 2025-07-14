class AddOrganizationToLikes < ActiveRecord::Migration[7.1]
  def change
    add_reference :likes, :organization, null: true, foreign_key: true
    
    add_index :likes, [:organization_id, :user_id, :post_id], unique: true, name: 'index_likes_on_org_user_post'
    
    # Set organization_id based on user's organization
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE likes 
          SET organization_id = users.organization_id
          FROM users
          WHERE likes.user_id = users.id
        SQL
        
        # Remove old unique index and make organization_id required
        remove_index :likes, [:user_id, :post_id]
        change_column_null :likes, :organization_id, false
      end
      
      dir.down do
        add_index :likes, [:user_id, :post_id], unique: true
      end
    end
  end
end
class AddJtiToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :jti, :string, null: false
    add_index :users, :jti, unique: true
    
    # Set JTI for existing users using raw SQL to avoid acts_as_tenant issues
    reversible do |dir|
      dir.up do
        # Generate UUIDs for existing users
        connection.execute <<-SQL
          UPDATE users 
          SET jti = substr(md5(random()::text || id::text), 1, 32)
          WHERE jti IS NULL OR jti = ''
        SQL
      end
    end
  end
end
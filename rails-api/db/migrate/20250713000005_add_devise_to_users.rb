class AddDeviseToUsers < ActiveRecord::Migration[7.1]
  def change
    # Add Devise fields
    add_column :users, :encrypted_password, :string, null: false, default: ""
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
    
    # Add name fields
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone, :string
    
    # Add indexes
    add_index :users, :reset_password_token, unique: true
    
    # Make uid nullable for non-Google users
    change_column_null :users, :uid, true
  end
end
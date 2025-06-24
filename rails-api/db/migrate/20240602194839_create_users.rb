class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :image
      t.string :username
      t.string :uid, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :uid, unique: true
  end
end
class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.integer :post_id
      t.string :hash_id
      t.string :source
      t.text :metadata
      t.string :filename

      t.timestamps
    end
  end
end

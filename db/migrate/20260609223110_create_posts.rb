class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.integer :visits
      t.string :extract
      t.integer :cate, default: 0

      t.timestamps
    end
  end
end

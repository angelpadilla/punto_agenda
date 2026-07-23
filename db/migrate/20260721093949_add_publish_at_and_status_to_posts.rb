class AddPublishAtAndStatusToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :publish_at, :datetime
    add_column :posts, :status, :integer, default: 0, null: false

    add_index :posts, :publish_at
    add_index :posts, :status
  end
end

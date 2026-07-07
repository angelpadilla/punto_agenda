class AddTelegramToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :telegram_id, :bigint
    add_column :users, :telegram_link_token, :string
    add_column :users, :telegram_linked_at, :datetime
    add_index :users, :telegram_id, unique: true
    add_index :users, :telegram_link_token
  end
end

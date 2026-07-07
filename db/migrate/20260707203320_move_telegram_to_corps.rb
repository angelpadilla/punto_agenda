class MoveTelegramToCorps < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :telegram_link_token, if_exists: true
    remove_index :users, :telegram_id, if_exists: true
    remove_column :users, :telegram_id, :bigint, if_exists: true
    remove_column :users, :telegram_link_token, :string, if_exists: true
    remove_column :users, :telegram_linked_at, :datetime, if_exists: true

    add_column :corps, :telegram_id, :bigint
    add_column :corps, :telegram_link_token, :string
    add_column :corps, :telegram_linked_at, :datetime
    add_index :corps, :telegram_id, unique: true
    add_index :corps, :telegram_link_token
  end
end

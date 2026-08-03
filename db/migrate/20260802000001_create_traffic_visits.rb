class CreateTrafficVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :traffic_visits do |t|
      t.string :source, default: "other", null: false
      t.string :path, null: false
      t.string :event_type, default: "visit", null: false
      t.string :referer
      t.string :referer_host
      t.string :fbclid
      t.timestamps
    end

    add_index :traffic_visits, :source
    add_index :traffic_visits, :created_at
    add_index :traffic_visits, :path
    add_index :traffic_visits, :event_type
  end
end

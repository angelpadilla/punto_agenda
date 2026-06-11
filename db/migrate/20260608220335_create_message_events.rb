class CreateMessageEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :message_events do |t|
      t.string :body
      t.string :to
      t.string :prefix
      t.references :corp, null: false, foreign_key: true
      t.integer :status

      t.belongs_to :eventeable, polymorphic: true

      t.timestamps
    end

  end
end

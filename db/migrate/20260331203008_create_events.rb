class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title
      t.text :body
      t.datetime :hora_inicio
      t.datetime :hora_final
      t.references :customer, null: false, foreign_key: true
      t.references :corp, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

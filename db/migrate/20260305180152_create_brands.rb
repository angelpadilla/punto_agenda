class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name
      t.string :body

      t.timestamps
    end
  end
end

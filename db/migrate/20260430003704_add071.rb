class Add071 < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :folio, :string
  end
end

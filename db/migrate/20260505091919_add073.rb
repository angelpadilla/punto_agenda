class Add073 < ActiveRecord::Migration[8.1]
  def change
    add_column :deposits, :folio, :string
  end
end

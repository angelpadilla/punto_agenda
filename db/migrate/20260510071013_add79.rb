class Add79 < ActiveRecord::Migration[8.1]
  def change
    change_column :users, :tipo, :string, default: "colaborador"
  end
end

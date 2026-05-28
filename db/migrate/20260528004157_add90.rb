class Add90 < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :motivo_cancelacion, :string
  end
end

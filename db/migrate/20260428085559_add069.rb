class Add069 < ActiveRecord::Migration[8.1]
  def change
    change_column :corps, :rfc, :string, default: "XAXX010101000"
  end
end

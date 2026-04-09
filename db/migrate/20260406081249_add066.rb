class Add066 < ActiveRecord::Migration[8.1]
  def change
    change_column :orders, :tipo, :string, default: "carrito"
    change_column :orders, :status_pago, :string, default: "pagado"
  end
end

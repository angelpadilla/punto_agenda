class Add109 < ActiveRecord::Migration[8.1]
  def change
    add_column :line_items, :name, :string
    add_column :line_items, :body, :string
    # add_column :corp, :stripe_account_id, :string
    add_column :deposits, :comision_sitio, :decimal, precision: 17, scale: 4, default: 0.0
    add_column :deposits, :status_pago, :integer, default: 0
    add_column :deposits, :error, :string
    add_column :orders, :comision_sitio, :decimal, precision: 17, scale: 4, default: 0.0
    add_column :orders, :comision_terminal, :decimal, precision: 17, scale: 4, default: 0.0
    add_column :bills, :direccion, :integer, default: 0

    add_reference :orders, :event, foreign_key: true
  end
end

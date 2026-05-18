class CreateCorpCustomers < ActiveRecord::Migration[8.1]
  def up
    create_table :corp_customers do |t|
      t.references :corp, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :source, default: "manual"

      t.timestamps
      t.index [ :corp_id, :customer_id ], unique: true
    end

    execute <<~SQL
      INSERT INTO corp_customers (corp_id, customer_id, source, created_at, updated_at)
      SELECT corp_id, id, 'manual', NOW(), NOW()
      FROM customers
      WHERE corp_id IS NOT NULL
    SQL

    # Then remove the column (after validating the data)
    remove_reference :customers, :corp, foreign_key: true
  end

  def down
    add_reference :customers, :corp, foreign_key: true
    execute <<~SQL
      UPDATE customers
      SET corp_id = corp_customers.corp_id
      FROM corp_customers
      WHERE customers.id = corp_customers.customer_id
    SQL
    drop_table :corp_customers
  end
end

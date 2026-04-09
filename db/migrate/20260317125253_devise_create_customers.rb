# frozen_string_literal: true

class DeviseCreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at


      t.timestamps null: false

      t.string :tel
      t.integer :tipo, default: 0
      t.references :corp, null: false, foreign_key: true
      t.string :rfc, default: "XAXX010101000"
      t.string :curp
      t.string :regimen, default: "616"
      t.string :razon
      t.string :calle
      t.string :colonia
      t.string :localidad
      t.string :ciudad
      t.string :estado
      t.string :cp
      t.string :num_int
      t.string :num_ext
      t.boolean :active, default: true
      t.decimal :credit, precision: 17, scale: 4, default: "0.0"

    end

    add_index :customers, :email,                unique: true
    add_index :customers, :reset_password_token, unique: true
    # add_index :customers, :confirmation_token,   unique: true
    add_index :customers, :unlock_token,         unique: true
  end
end

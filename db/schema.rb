# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_30_003704) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "brands", force: :cascade do |t|
    t.string "body"
    t.integer "corp_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["corp_id"], name: "index_brands_on_corp_id"
  end

  create_table "corps", force: :cascade do |t|
    t.text "business_hours"
    t.boolean "calendar", default: false
    t.string "calle"
    t.string "ciudad"
    t.string "colonia"
    t.string "cp"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "estado"
    t.string "facebook_url"
    t.boolean "facturacion", default: false
    t.string "instagram_url"
    t.string "key_pass"
    t.string "localidad"
    t.string "name"
    t.string "num_ext"
    t.string "num_int"
    t.boolean "online_payments", default: false
    t.string "phone"
    t.boolean "public_site", default: false
    t.string "razon"
    t.string "regimen"
    t.string "rfc", default: "XAXX010101000"
    t.string "sku"
    t.string "text_cotizacion"
    t.string "text_factura"
    t.string "text_remision"
    t.string "tiktok_url"
    t.integer "timbres"
    t.string "tipo_negocio"
    t.datetime "updated_at", null: false
    t.boolean "visto", default: false
    t.string "whatsapp"
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "calle"
    t.string "ciudad"
    t.string "colonia"
    t.integer "corp_id", null: false
    t.string "cp"
    t.datetime "created_at", null: false
    t.decimal "credit", precision: 17, scale: 4, default: "0.0"
    t.string "curp"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "estado"
    t.integer "failed_attempts", default: 0, null: false
    t.integer "failed_events", default: 0
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.decimal "limite_credito", precision: 17, scale: 2, default: "0.0"
    t.string "localidad"
    t.datetime "locked_at"
    t.text "notas"
    t.string "num_ext"
    t.string "num_int"
    t.integer "orders_count", default: 0
    t.string "passs"
    t.string "razon"
    t.string "regimen", default: "616"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "rfc", default: "XAXX010101000"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "success_events", default: 0
    t.string "tel"
    t.integer "tipo", default: 0
    t.integer "total_events", default: 0
    t.decimal "total_spent", precision: 17, scale: 2, default: "0.0"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["corp_id"], name: "index_customers_on_corp_id"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_customers_on_unlock_token", unique: true
  end

  create_table "deposits", force: :cascade do |t|
    t.decimal "comision_terminal", precision: 17, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.integer "depositable_id"
    t.string "depositable_type"
    t.string "forma_pago"
    t.string "moneda", default: "MXN"
    t.decimal "monto", precision: 17, scale: 4
    t.string "num_operacion"
    t.text "sat_cfdi"
    t.string "sat_error"
    t.text "sat_sello"
    t.text "sat_serial"
    t.text "sat_uuid"
    t.string "stamp_date"
    t.integer "tipo", null: false
    t.datetime "updated_at", null: false
    t.text "uso_cfdi"
    t.text "xml"
    t.index ["depositable_type", "depositable_id"], name: "index_deposits_on_depositable"
  end

  create_table "events", force: :cascade do |t|
    t.text "body"
    t.integer "corp_id", null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "folio"
    t.datetime "hora_final"
    t.datetime "hora_inicio"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["corp_id"], name: "index_events_on_corp_id"
    t.index ["customer_id"], name: "index_events_on_customer_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.decimal "alerta_stock", precision: 12, scale: 4
    t.decimal "average_duration_event", precision: 15, scale: 2, default: "0.0"
    t.string "bar_code"
    t.integer "brand_id"
    t.integer "cate"
    t.integer "corp_id", null: false
    t.decimal "cost", precision: 17, scale: 4
    t.datetime "created_at", null: false
    t.text "desc"
    t.string "error"
    t.string "garantia"
    t.string "name"
    t.decimal "offer", precision: 17, scale: 4
    t.integer "orders_count", default: 0
    t.decimal "price", precision: 17, scale: 4
    t.decimal "price2", precision: 17, scale: 4
    t.decimal "price3", precision: 17, scale: 4
    t.integer "sat_product_id", null: false
    t.string "sku"
    t.integer "status", default: 0
    t.decimal "stock", precision: 17, scale: 4, default: "0.0"
    t.decimal "total_revenue", precision: 17, scale: 2, default: "0.0"
    t.string "unidad"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_items_on_brand_id"
    t.index ["corp_id"], name: "index_items_on_corp_id"
    t.index ["sat_product_id"], name: "index_items_on_sat_product_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.decimal "cantidad", precision: 17, scale: 4
    t.string "comentario"
    t.decimal "costo", precision: 17, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.decimal "descuento", precision: 17, scale: 4, default: "0.0"
    t.string "error"
    t.integer "item_id"
    t.decimal "iva", precision: 17, scale: 4, default: "16.0"
    t.integer "order_id", null: false
    t.decimal "precio", precision: 17, scale: 4
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_line_items_on_item_id"
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.decimal "abonado", precision: 17, scale: 4, default: "0.0"
    t.integer "corp_id", null: false
    t.decimal "costo", precision: 17, scale: 4
    t.decimal "costo_terminal", precision: 17, scale: 4
    t.datetime "created_at", null: false
    t.integer "customer_id"
    t.date "deadline"
    t.decimal "debe", precision: 17, scale: 4, default: "0.0"
    t.decimal "descuento", precision: 17, scale: 4, default: "0.0"
    t.string "error"
    t.date "fecha"
    t.string "folio"
    t.string "forma_pago"
    t.decimal "ganancia", precision: 17, scale: 4
    t.decimal "impuestos", precision: 17, scale: 4
    t.string "moneda", default: "MXN"
    t.text "nota_customer"
    t.text "nota_interna"
    t.text "sat_cfdi"
    t.text "sat_sello"
    t.string "sat_sello_emisor"
    t.string "sat_serial"
    t.string "sat_timbre_fecha"
    t.string "sat_uuid"
    t.integer "seller_id"
    t.string "status_pago", default: "pagado"
    t.decimal "subtotal", precision: 17, scale: 4
    t.string "tipo", default: "carrito"
    t.decimal "total", precision: 17, scale: 4
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "uso_cfdi"
    t.text "xml"
    t.index ["corp_id"], name: "index_orders_on_corp_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "calle"
    t.string "ciudad"
    t.string "colonia"
    t.integer "corp_id", null: false
    t.string "cp"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "estado"
    t.string "localidad"
    t.text "notas"
    t.string "num_ext"
    t.string "num_int"
    t.string "razon"
    t.string "regimen", default: "616"
    t.string "rfc", default: "XAXX010101000"
    t.string "tel"
    t.datetime "updated_at", null: false
    t.index ["corp_id"], name: "index_providers_on_corp_id"
  end

  create_table "sat_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "sku"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "average_rating", default: 0
    t.integer "completed_events", default: 0
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.integer "corp_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "full_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "tel"
    t.string "tipo", default: "usuario"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["corp_id"], name: "index_users_on_corp_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brands", "corps"
  add_foreign_key "customers", "corps"
  add_foreign_key "events", "corps"
  add_foreign_key "events", "customers"
  add_foreign_key "events", "users"
  add_foreign_key "items", "brands"
  add_foreign_key "items", "corps"
  add_foreign_key "items", "sat_products"
  add_foreign_key "line_items", "items"
  add_foreign_key "line_items", "orders"
  add_foreign_key "orders", "corps"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "users"
  add_foreign_key "providers", "corps"
  add_foreign_key "users", "corps"
end

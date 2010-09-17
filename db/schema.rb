# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100830184453) do

  create_table "actors", :force => true do |t|
    t.string   "name"
    t.integer  "actor_number"
    t.string   "actor_type"
    t.string   "billing_address_1"
    t.string   "billing_address_2"
    t.string   "billing_address_3"
    t.string   "billing_city"
    t.string   "billing_state"
    t.string   "billing_zip",            :limit => 20
    t.string   "billing_country"
    t.string   "billing_recipient_name"
    t.string   "billing_phone",          :limit => 25
    t.string   "billing_email"
    t.string   "billing_province"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "meta_data"
    t.string   "created_by_username"
    t.integer  "created_by_user_number"
  end

  add_index "actors", ["name"], :name => "index_actors_on_name", :unique => true

  create_table "applied_rules", :force => true do |t|
    t.integer  "applied_to_order_id"
    t.integer  "rule_id"
    t.string   "rule_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applied_rules", ["applied_to_order_id"], :name => "index_applied_rules_on_applied_to_order_id"

  create_table "billing_cycles", :force => true do |t|
    t.string   "state"
    t.datetime "start_date"
    t.datetime "end_date"
  end

  add_index "billing_cycles", ["start_date", "end_date"], :name => "index_billing_cycles_on_start_date_and_end_date", :unique => true

  create_table "dirty_invoice_markers", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "billed_actor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "granted_awards", :force => true do |t|
    t.integer  "granted_award_number"
    t.integer  "rule_definition_id"
    t.integer  "billed_actor_id"
    t.string   "product_type"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "quantity_awarded"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "awarded_by_username"
    t.string   "created_by_username"
    t.integer  "created_by_user_number"
  end

  create_table "id_generators", :force => true do |t|
    t.integer "last_seed",        :default => -1
    t.integer "number_adder"
    t.string  "purpose"
    t.integer "number_prime"
    t.integer "scrambled_digits"
  end

  create_table "invoice_line_items", :force => true do |t|
    t.integer  "order_id"
    t.integer  "quantity"
    t.string   "sku_name"
    t.string   "sku_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoice_line_items", ["order_id"], :name => "index_invoice_line_items_on_order_id"

  create_table "invoices", :force => true do |t|
    t.integer  "billed_actor_id"
    t.integer  "payed_actor_id"
    t.integer  "invoice_number"
    t.integer  "billing_cycle_id"
    t.datetime "last_regenerated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "billable"
    t.integer  "dirty_version"
    t.integer  "clean_version"
  end

  add_index "invoices", ["billed_actor_id", "payed_actor_id", "billing_cycle_id"], :name => "index_on_invoice_actor_billing", :unique => true

  create_table "order_line_items", :force => true do |t|
    t.integer  "order_id"
    t.integer  "quantity"
    t.string   "sku_name"
    t.string   "sku_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_line_items", ["order_id"], :name => "index_order_line_items_on_order_id"

  create_table "orders", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["invoice_id"], :name => "index_orders_on_invoice_id"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.text     "meta_data"
    t.string   "product_type"
    t.integer  "billed_actor_id"
    t.integer  "payed_actor_id"
    t.datetime "posted_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_number"
    t.string   "created_by_username"
    t.integer  "created_by_user_number"
  end

  create_table "promotions", :force => true do |t|
    t.integer  "promotion_number"
    t.string   "name"
    t.string   "promotion_type"
    t.string   "product_type"
    t.string   "billed_actor_type"
    t.integer  "billed_actor_id"
    t.string   "payed_actor_type"
    t.integer  "rule_definition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "usage_note"
    t.string   "created_by_username"
    t.integer  "created_by_user_number"
  end

  create_table "rule_definitions", :force => true do |t|
    t.string  "name"
    t.boolean "active"
    t.integer "sort_order"
    t.string  "product_type"
    t.string  "apply_type"
    t.string  "rule_type"
    t.text    "rule_data"
  end

  create_table "used_awards", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "granted_award_id"
    t.integer  "quantity_used"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

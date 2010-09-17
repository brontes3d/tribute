class InitialSchema < ActiveRecord::Migration
  
  def self.up
    create_table :products do |t|
      t.string   :name
      t.text     :meta_data
      t.string   :product_type
      t.integer  :billed_actor_id
      t.integer  :payed_actor_id
      t.integer  :product_number
      t.datetime :posted_date
      t.timestamps
    end
    create_table :actors do |t|
      t.string  :name
      t.integer :actor_number
      t.string  :actor_type
      
      t.string :billing_address_1
      t.string :billing_address_2
      t.string :billing_address_3
      t.string :billing_city
      t.string :billing_state
      t.string :billing_zip, :limit => 20
      t.string :billing_country
      t.string :billing_recipient_name
      t.string :billing_phone, :limit => 25
      t.string :billing_email
      t.string :billing_province
      
      t.timestamps
      t.text    :meta_data # this should ideally be at the end of the table for effciency
    end
    create_table :orders, :force => true do |t|
      t.integer :invoice_id
      t.integer :product_id
      t.timestamps
    end
    create_table :order_line_items, :force => true do |t|
      t.integer :order_id
      t.integer :quantity
      t.string  :sku_name
      t.string  :sku_number
      t.timestamps
    end
    
    create_table :applied_rules, :force => true do |t|
      t.integer :applied_to_order_id
      t.integer :rule_id
      t.string  :rule_type
      t.timestamps
    end
    
    create_table :promotions, :force => true do |t|
      t.integer :promotion_number
      t.string  :name
      t.string  :promotion_type
      t.string  :product_type
      t.string  :billed_actor_type
      t.integer :billed_actor_id
      t.string  :payed_actor_type
      t.integer :rule_definition_id
      t.timestamps
    end
    
    create_table :rule_definitions, :force => true do |t|
      t.string  :name
      t.boolean :active
      t.integer :sort_order
      t.string  :product_type
      t.string  :apply_type
      t.string  :rule_type
      t.text    :rule_data
    end
    
    create_table :granted_awards, :force => true do |t|
      t.integer :granted_award_number
      t.integer :rule_definition_id
      t.integer :billed_actor_id
      t.string  :product_type
      t.datetime :start_date
      t.datetime :end_date
      t.integer :quantity_awarded
      t.text    :notes
      t.timestamps
    end
    
    create_table :used_awards, :force => true do |t|
      t.integer :invoice_id
      t.integer :granted_award_id
      t.integer :quantity_used
      t.timestamps
    end
    
    create_table :invoices, :force => true do |t|
      t.integer  :billed_actor_id
      t.integer  :payed_actor_id
      t.integer  :invoice_number
      t.integer  :billing_cycle_id
      t.boolean  :dirty
      t.boolean  :billable
      t.datetime :last_regenerated_at
      t.timestamps
    end
    create_table :invoice_line_items, :force => true do |t|
      t.integer :order_id
      t.integer :quantity
      t.string  :sku_name
      t.string  :sku_number
      t.timestamps
    end
    
    create_table :id_generators, :force => true do |t|
      t.integer :last_seed,                :default => -1
      t.integer :number_adder
      t.integer :number_prime
      t.integer :scrambled_digits
      t.string  :purpose
    end
    
    create_table :billing_cycles, :force => true do |t|
      t.string   :state
      t.datetime :start_date
      t.datetime :end_date
    end
    
  end

  def self.down
    drop_table :products
    drop_table :actors
    drop_table :orders
    drop_table :order_line_items
    drop_table :promotions
    drop_table :granted_awards
    drop_table :used_awards
    drop_table :invoices
    drop_table :invoice_line_items
    drop_table :rule_definitions
    drop_table :id_generators
    drop_table :billing_cycles
    drop_table :applied_rules
  end

end

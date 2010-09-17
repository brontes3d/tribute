class AddOrderIdIndexOnOrderLineItems < ActiveRecord::Migration
  def self.up
    add_index :order_line_items, :order_id
  end

  def self.down
    remove_index :order_line_items, :order_id
  end
end

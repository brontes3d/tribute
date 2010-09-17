class AddIndexesForXmlExport < ActiveRecord::Migration
  def self.up
    add_index :invoice_line_items, :order_id
    add_index :invoices, [:billing_cycle_id, :payed_actor_id]
  end

  def self.down
    remove_index :invoices, [:billing_cycle_id, :payed_actor_id]
    remove_index :invoice_line_items, :order_id
  end
end

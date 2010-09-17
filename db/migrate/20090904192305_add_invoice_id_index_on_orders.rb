class AddInvoiceIdIndexOnOrders < ActiveRecord::Migration
  def self.up
    add_index :orders, :invoice_id
  end

  def self.down
    remove_index :orders, :invoice_id
  end
end

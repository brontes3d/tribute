class InvoiceUniqueIndex < ActiveRecord::Migration
  def self.up
    add_index :invoices, [:billed_actor_id, :payed_actor_id, :billing_cycle_id], :unique => true, :name => 'index_on_invoice_actor_billing'
  end

  def self.down
    remove_index :invoices, :name => 'index_on_invoice_actor_billing'
  end
end

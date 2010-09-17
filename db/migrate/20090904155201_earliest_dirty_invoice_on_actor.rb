class EarliestDirtyInvoiceOnActor < ActiveRecord::Migration
  def self.up
    add_column :actors, :earliest_dirty_invoice_billed_to_me_id, :integer
  end

  def self.down
    remove_column :actors, :earliest_dirty_invoice_billed_to_me_id
  end
end

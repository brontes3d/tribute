class CreateDirtyInvoiceMarkers < ActiveRecord::Migration
  def self.up
    create_table :dirty_invoice_markers, :force => true do |t|
      t.integer :invoice_id
      t.integer :billed_actor_id
      t.timestamps
    end
    remove_column :actors, :earliest_dirty_invoice_billed_to_me_id
    add_column :invoices, :dirty_version, :integer
    add_column :invoices, :clean_version, :integer
    remove_column :invoices, :dirty
  end

  def self.down
    add_column :invoices, :dirty, :boolean
    remove_column :invoices, :clean_version
    remove_column :invoices, :dirty_version
    add_column :actors, :earliest_dirty_invoice_billed_to_me_id, :integer
    drop_table :dirty_invoice_markers
  end
end

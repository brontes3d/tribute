class CleanupOrphanedInvoices < ActiveRecord::Migration
  def self.up
    # select * from invoices left join orders on orders.invoice_id = invoices.id where dirty_version <> clean_version AND orders.id IS NULL;
    Invoice.reset_column_information
    Order.reset_column_information
    invoices = Invoice.find(:all, :conditions => "dirty_version <> clean_version AND orders.id IS NULL", :include => ['orders'])
    invoices.each do |inv|
      if inv.open?
        inv.regenerate        
      else
        inv.destroy
        DirtyInvoiceMarker.invoice_destroyed!(inv)        
      end
    end
  end

  def self.down
  end
end

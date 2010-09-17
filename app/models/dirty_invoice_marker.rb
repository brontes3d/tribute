class DirtyInvoiceMarker < ActiveRecord::Base
  
  def self.invoice_made_dirty!(invoice)
    @message_sent = false
    invoice.commit_callback do
      unless @message_sent
        AmqpListener.send("dirty_invoices", invoice.invoice_number)
        @message_sent = true
      end
    end
    invoice.increment!(:dirty_version)
    while !invoice.dirty?
      invoice.increment!(:dirty_version)
    end
    marker = find_or_create_marker(invoice)
    marker.might_change_earliest_dirty_invoice_billed_to_me!(invoice)
  end

  def self.invoice_made_clean!(invoice)
    invoice.clean_version = invoice.dirty_version
    invoice.last_regenerated_at = Time.now
    invoice.save!
    invoice.ensure_atomic_update!
    invoice.reload
    if invoice.clean?
      marker = find_or_create_marker(invoice)
      marker.might_change_earliest_dirty_invoice_billed_to_me!(invoice)
    end
  end
  
  def self.invoice_destroyed!(invoice)
    marker = find_or_create_marker(invoice)
    if marker.invoice_id == invoice.id
      marker.invoice = nil
      marker.save!
    end
  end
  
  def self.find_or_create_marker(invoice)
    marker = DirtyInvoiceMarker.find_by_billed_actor_id(invoice.billed_actor_id) || 
             DirtyInvoiceMarker.create!(:billed_actor => invoice.billed_actor)    
  end
  
  belongs_to :invoice
  belongs_to :billed_actor, :class_name => "Actor"
  
  def might_change_earliest_dirty_invoice_billed_to_me!(given_invoice)
    if given_invoice.dirty?
      if given_invoice_comes_before_earliest?(given_invoice)
        self.invoice = given_invoice
        self.save!
      end
    else
      if self.invoice == given_invoice
        self.invoice = nil
        self.save!
      end
    end
  end

  def given_invoice_comes_before_earliest?(given_invoice)
    !self.invoice ||
    given_invoice.start_date < self.invoice.start_date
  end
  
end
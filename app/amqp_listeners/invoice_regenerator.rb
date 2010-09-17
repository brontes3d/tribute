class InvoiceRegenerator < AmqpListener::Listener
  
  subscribes_to :dirty_invoices
  
  def on_message(message)
    if invoice = Invoice.find_by_invoice_number(message)
      #regenerate this invoice, if it's the earliest dirty one billed_actor
      
      invoice_to_regen = 
        if invoice.billed_actor.given_invoice_comes_before_earliest?(invoice) && invoice.dirty?
          invoice
        else
          #if there is an earlier invoice then this regenerate that
          invoice.billed_actor.earliest_dirty_invoice_billed_to_me
        end
      
      if invoice_to_regen
        InvoiceRegenerator.regen_invoice(invoice_to_regen)
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    if e.message.to_s.include?("lock")
      Rails.logger.warn("Error while processing #{message.to_yaml}")
      Rails.logger.warn(e.inspect + "\n" + e.backtrace.join("\n"))
      sleep(1)
      retry
    else
      raise e
    end
  rescue Invoice::AlreadyCleaned
    #ignore
  end
  
  def self.regen_invoice(invoice_to_regen)
    ms = Benchmark.ms{ invoice_to_regen.regenerate }
    # puts "regenerating invoice #{invoice_to_regen.invoice_number} with #{invoice_to_regen.orders.size} orders, took #{ms} ms"
    #dirty the next invoice
    # puts "invoice_to_regen.clean? #{invoice_to_regen.clean?} -- invoice_to_regen.frozen? #{invoice_to_regen.frozen?}"
    if (invoice_to_regen.clean? || #if it wasn't successfully cleaned?
        invoice_to_regen.frozen? #or if it was destroyed (TODO: change to .destroyed? when rails supports this)
        ) && next_invoice = find_next_open_invoice(invoice_to_regen.billed_actor_id, 
                                                   invoice_to_regen.billing_cycle) #and then if a "next invoice" exists
    then
      # puts "marking dirty #{next_invoice.inspect}"
      #mark it as dirty (Which should send a message to have it regenerated)
      next_invoice.dirty!
    end    
  end
  
  private
  
  def self.find_next_open_invoice(billed_actor_id, given_billing_cycle)
    if next_billing_cycle = given_billing_cycle.next
      # puts "next_billing_cycle #{next_billing_cycle.inspect}"
      # puts "given_invoice.billed_actor_id #{given_invoice.billed_actor_id}"
      if next_invoice = next_billing_cycle.invoices.find_by_billed_actor_id(billed_actor_id)
        if next_billing_cycle.open?
          return next_invoice
        else
          return find_next_open_invoice(billed_actor_id, next_billing_cycle)
        end
      else
        return find_next_open_invoice(billed_actor_id, next_billing_cycle)
      end
    end
    return nil
  end  
  
end
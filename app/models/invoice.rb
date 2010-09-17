class Invoice < ActiveRecord::Base
  
  belongs_to :billed_actor, :class_name => "Actor"
  belongs_to :payed_actor, :class_name => "Actor"
  belongs_to :billing_cycle
  
  validates_presence_of :billed_actor
  validates_presence_of :payed_actor
  validates_presence_of :billing_cycle
  
  #cannot have 2 invoices in the same billing cycle
  validates_uniqueness_of :billing_cycle_id, :scope => [:billed_actor_id, :payed_actor_id]
    
  has_many :orders, :dependent => :destroy
  has_many :used_awards, :dependent => :destroy
  
  include IdGeneration
  
  def closed?
    self.billing_cycle.closed?
  end  
  
  def open?
    self.billing_cycle.open?
  end
  
  def start_date
    self.billing_cycle.start_date if self.billing_cycle
  end
  
  def end_date
    self.billing_cycle.end_date if self.billing_cycle  
  end
  
  def current_as_of
    if dirty?
      self.last_regenerated_at || self.created_at
    else
      Time.zone.now
    end
  end
  
  def dirty?
    self.dirty_version != self.clean_version
  end
  
  def clean?
    not dirty?
  end
  
  def dirty!
    DirtyInvoiceMarker.invoice_made_dirty!(self)
  end
  
  class AlreadyCleaned < ActiveRecord::Rollback
  end

  #make what should be 'meaningless' increments of both clean_version and dirty_version
  #but if the increments fail, we know we have a lock conflict
  #I should probably just add a lock_version column to invoice instead of doing this
  #... but I havn't thought it through far enough
  #and this passes the tests... so I'm happy with it for now.
  def ensure_atomic_update!
    quoted_col_name_clean = connection.quote_column_name('clean_version')
    quoted_col_name_dirty = connection.quote_column_name('dirty_version')    
    affected_rows = connection.update(<<-end_sql, "#{self.class.name} Update with 'clean/dirty version' locking")
      UPDATE #{self.class.quoted_table_name}
      SET dirty_version = dirty_version + 1, clean_version = clean_version + 1
      WHERE #{self.class.primary_key} = #{quote_value(id)}
      AND #{quoted_col_name_clean} = #{quote_value(self.clean_version)} 
      AND #{quoted_col_name_dirty} = #{quote_value(self.dirty_version)}
    end_sql
    
    unless affected_rows == 1
      raise AlreadyCleaned, 
            "Attempted to update clean_version on an invoice already cleaned up to that version"
    end
  end
  
  #TODO: test this method
  def count_of_sku(sku)
    count = 0
    self.orders.each do |o|
      o.invoice_line_items.each do |iv|
        if iv.sku_number == sku.number
          count += iv.quantity
        end
      end
    end
    return count
  end
  
  def self.create_invoice(billed_actor, payed_actor, billing_cycle)
    invoice = Invoice.new(:billed_actor => billed_actor, :payed_actor => payed_actor,
                          :billing_cycle => billing_cycle,
                          :dirty_version => 1, :clean_version => 0)
    invoice.save!
    invoice
  end
  
  def self.find_invoice(billed_actor, payed_actor, billing_cycle)
    Invoice.find(:first, 
      :conditions => [
        "billed_actor_id = ? AND payed_actor_id = ? AND billing_cycle_id = ? ", 
        billed_actor.id, payed_actor.id, billing_cycle.id
      ])
  end
  
  def self.find_or_create_invoice(opts = {})
    billed_actor = opts[:billed_actor]
    payed_actor  = opts[:payed_actor]
    billing_cycle = opts[:billing_cycle] || 
                    BillingCycle.find_or_create_for_date(opts[:posted_date])
    invoice = find_invoice(billed_actor, payed_actor, billing_cycle)
    unless invoice
      begin      
        invoice = create_invoice(billed_actor, payed_actor, billing_cycle)
      rescue ActiveRecord::StatementInvalid => e
        Invoice.truly_in_seperate_transaction do
          invoice = find_invoice(billed_actor, payed_actor, billing_cycle)
        end
      end
    end
    return invoice
  end
  
  def find_or_create_next_open_invoice
    next_invoice = Invoice.find_or_create_invoice(:billed_actor => self.billed_actor,
                                                  :payed_actor => self.payed_actor,
                                                  :posted_date => self.end_date + 1.day)    
    if next_invoice.open?
      return next_invoice
    else
      return next_invoice.find_or_create_next_open_invoice
    end
  end
  
  def regenerate
    if self.orders.size > 0
      unless self.open?
        #Don't allow regeneration if this invoice belongs to a closed billing cycle
        #but DO allow regeneration (meaning deletion) if there are zero orders... 
        #since this does not affect quantity of each SKU billed in a billing cycle
        raise ArgumentError, "Can't regenerate this invoice #{self.invoice_number} because the billing cycle has been closed"
      end
      
      #load what we are going to need ahead of time
      orders_prefetched = self.orders.all(:include => ['product','order_line_items'])
      
      #reset billable state of invoice
      self.billable = true
      
      #load all applicable awards and promotions
      granted_awards = (billed_actor.granted_awards.in_billing_cycle(self.billing_cycle) + 
                        self.used_awards.collect(&:granted_award) ).uniq #TODO: the self.used_awards might not work completely...
      global_promotions = GlobalPromotion.find_all_by_billed_actor_type(billed_actor.class.name)
      awarded_promotions = billed_actor.awarded_promotions

      #populate the rule monger with relevant facts (editable + readable) and rules
      rule_monger = RuleMonger.new(self)
      rule_monger.add_editable('orders', orders_prefetched)
      rule_monger.add_editable('invoice_billable', self.billable)
      if billed_actor.object_name_for_rules != payed_actor.object_name_for_rules
        rule_monger.add_readbale(billed_actor.object_name_for_rules, billed_actor)
        rule_monger.add_readbale(payed_actor.object_name_for_rules, payed_actor)
      end
      rule_monger.add_readbale("billed_"+billed_actor.object_name_for_rules, billed_actor)
      rule_monger.add_readbale("payed_"+payed_actor.object_name_for_rules, payed_actor)
      rule_monger.rules = global_promotions + awarded_promotions + granted_awards        
      
      Invoice.transaction do
        #run rule monger
        results = rule_monger.run!
        
        #update invoice/orders based on result
        self.billable = results['invoice_billable']
        results["orders"].each do |modified_order|
          order = orders_prefetched.detect{ |o| o.id == modified_order['id'] }
          order.applied_rules.destroy_all
          order.invoice_line_items.destroy_all
          if self.billable
            order.editable_attributes.each do |att, v|
              value = modified_order[att]
              if value > 0
                InvoiceLineItem.create!(:order => order, :sku => SKU.lookup(att), :quantity => value)
              end
            end
          end
        end
        
        #record which rules were used in this regeneration
        record_rule_applications(orders_prefetched, rule_monger.rules_applied)
        
        #done regenerating
        DirtyInvoiceMarker.invoice_made_clean!(self)
      end
    else
      Invoice.transaction do
        self.destroy
        DirtyInvoiceMarker.invoice_destroyed!(self)
      end
    end
  end
  
  
  def sku_totals(opts={})
    info = []
    
    grouped_by_skus = self.class.find_by_sql("SELECT invoice_line_items.sku_name, invoice_line_items.sku_number, SUM(invoice_line_items.quantity) AS total_sku_count 
        FROM `invoices` LEFT OUTER JOIN `orders` ON orders.invoice_id = invoices.id 
        LEFT OUTER JOIN `invoice_line_items` ON invoice_line_items.order_id = orders.id
        WHERE `invoices`.billing_cycle_id = #{billing_cycle.id}
        AND `invoices`.payed_actor_id = #{payed_actor.id}
        AND `invoices`.id = #{self.id}
        AND `invoice_line_items`.id IS NOT NULL
        GROUP BY invoice_line_items.sku_number
        ORDER BY invoice_line_items.sku_number ASC"
    )
    
    exclude_skus = opts[:exclude_skus] || []
    logger.debug { "gather_invoice_information : grouped_by_skus = #{grouped_by_skus.inspect}" }
    grouped_by_skus.each do |sku_total|
      unless exclude_skus.include?(sku_total.sku_number.to_i)
        info << {:sku_name => sku_total.sku_name, :sku_number => sku_total.sku_number, :count => sku_total.total_sku_count}
      end
    end
    
    logger.debug { "gather_invoice_information : info = #{info.inspect}" }
    info
  end
  
  private
  
  def record_rule_applications(orders_prefetched, rules_applied)
    rules_applied.each do |rule_applied|
      if order_changes = rule_applied.changes['orders']
        paired_order_changes = []
        order_changes[0].each_with_index{ |oc, index|  paired_order_changes[index] = [oc] }
        order_changes[1].each_with_index{ |oc, index|  paired_order_changes[index] << oc }
        paired_order_changes.each do |order_before, order_after|
          if order_before != order_after
            if real_order = orders_prefetched.detect{ |o| o.id == order_before['id'] }
              real_order.applied_rules.create(:rule => rule_applied.rule)
            end
          end
        end
      end
    end
  end
  
end
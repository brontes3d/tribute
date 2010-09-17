class GrantedAward < ActiveRecord::Base

  include AuditCreatedByUser
  
  belongs_to :rule_definition
  validates_presence_of_association :rule_definition
  
  belongs_to :billed_actor, :class_name => "Actor"
  validates_presence_of_association :billed_actor
  
  has_many :used_awards, :dependent => :destroy
  
  #TODO: validate that the billed actor is of type rule_definition.billed_actor_type
  include IdGeneration
  
  validate do |ga|
    if ga.rule_definition
      ga.product_type = ga.rule_definition.product_type.to_s
    end
  end
  
  validates_presence_of :quantity_awarded
  validate do |ga|
    if ga.quantity_awarded.to_i <= 0
      ga.errors.add(:quantity_awarded, "must be greater than zero")
    end
    quantity_used = ga.quantity_used_in_closed_invoices
    if ga.quantity_awarded.to_i < quantity_used
      ga.errors.add(:quantity_awarded, 
                    "must be greater than or equal to the number already used in closed invoices (#{quantity_used})")      
    end
  end
  validates_presence_of :start_date, :end_date
  
  validate do |ga|
    if ga.end_date < ga.start_date
      ga.errors.add(:end_date, "must be after start date")
    end
  end
  
  named_scope :in_billing_cycle, Proc.new { |billing_cycle|
    {:conditions => ["start_date <= ? AND end_date >= ?", billing_cycle.start_date, billing_cycle.end_date]}
  }
  
  def in_billing_cycle?(billing_cycle)
    self.start_date <= billing_cycle.start_date && self.end_date >= billing_cycle.end_date
  end
  
  # This code logically really belongs to the controller... 
  # but the way rails implements the date select, this is really the easiest place to intersect and override
  def assign_multiparameter_attributes(pairs)
    #Override to customize the setting of start_date and end_date as set by controller
    #but maintain the ability to set to something more specific via script/console    
    to_super = []
    date_parts = {}
    pairs.each do |pair|
      if pair.to_s.index("start_date") || pair.to_s.index("end_date")
        date_parts[pair[0]] = pair[1]
      else
        to_super << pair
      end
    end
    unless date_parts.empty?
      #extract start_date    
      self.start_date = BillingCycle.time_for_month_year(date_parts["start_date(2i)"], date_parts["start_date(1i)"]).beginning_of_month
      #extract end_date    
      self.end_date = BillingCycle.time_for_month_year(date_parts["end_date(2i)"], date_parts["end_date(1i)"]).end_of_month
    end
    super(to_super)
  end
  
  after_save :dirty_invoices
  after_destroy :dirty_invoices  
  
  def dirty_invoices
    self.billed_actor.dirty_invoices
  end
  
  before_destroy :ensure_not_used_on_any_closed_invoices
  def ensure_not_used_on_any_closed_invoices
    if self.quantity_used_in_closed_invoices > 0
      raise ArgumentError, "Can't destroy this award because it's used on a closed invoice"
    end
  end
  
  def name
    "#{quantity_awarded} #{rule_definition.name} granted to #{billed_actor.name}"
  end
  
  def get_redirect_to_url(controller)
    return self.billed_actor.get_redirect_to_url(controller)
  end
  
  def quantity_used_in_closed_invoices
    quantity_used = 0
    self.used_awards.each do |ua|
      #if it was used in a closed invoice, then applu to the running total
      if ua.invoice.closed?
        quantity_used += ua.quantity_used
      end
    end
    quantity_used
  end
  
  def quantity_available_excluding_pending
    self.quantity_awarded - self.quantity_used_in_closed_invoices
  end
  
  def quantity_available_from_date(from_date)
    quantity_available = self.quantity_awarded
    self.used_awards.each do |ua|
      #if it was used in an 'older' invoice, then apply it to the running total of quantity_available
      if ua.invoice.closed? || ua.invoice.start_date < from_date
        quantity_available -= ua.quantity_used
      end
    end
    quantity_available
  end
  
  def run(rule_monger)
    invoice = rule_monger.invoice
    if self.in_billing_cycle?(invoice.billing_cycle)
      rule = self.rule_definition
      quantity_available = quantity_available_from_date(invoice.start_date)
    
      # puts "quantity_available before: " + quantity_available.inspect
    
      facts_edited = 
        rule_monger.with_facts(
          :readble => {:start_date => self.start_date, :end_date => self.end_date},
          :editable => {:quantity_awarded => quantity_available}
        ) do
          rule.run(rule_monger)
        end
      used_award = invoice.used_awards.find_by_granted_award_id(self.id)
    
      # puts "quantity_available after: " + facts_edited[:quantity_awarded].inspect
    
      if facts_edited[:quantity_awarded] &&
         facts_edited[:quantity_awarded] != quantity_available
        used_award ||= UsedAward.new(:granted_award => self, :invoice => invoice)
        used_award.quantity_used = quantity_available - facts_edited[:quantity_awarded]
        used_award.save!
      elsif used_award
        used_award.destroy
      end
    else
      if used_award = invoice.used_awards.find_by_granted_award_id(self.id)
        used_award.destroy
      end
    end
  end
  
end

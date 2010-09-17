class AwardedPromotion < Promotion
  
  belongs_to :billed_actor, :class_name => "Actor"
  
  validates_presence_of :billed_actor
  
  after_save :dirty_invoices
  after_destroy :dirty_invoices
  def dirty_invoices
    self.billed_actor.dirty_invoices
  end
  
  validates_uniqueness_of :rule_definition_id, :scope => :billed_actor_id
  
  def get_redirect_to_url(controller)
    if self.billed_actor && self.billed_actor.respond_to?(:get_redirect_to_url)
      self.billed_actor.get_redirect_to_url(controller)
    else
      controller.url_for(:action => 'show', :id => self)
    end
  end
  
  def name
    "#{rule_definition.name} granted to #{billed_actor.name}"    
  end
  
end
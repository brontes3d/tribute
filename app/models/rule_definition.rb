class RuleDefinition < ActiveRecord::Base
  
  validates_presence_of :sort_order
  #TODO: when there is an interface to edit rule definitions, we will need an interface to re-order them

  validates_uniqueness_of :name
  
  [:rule_type, :apply_type, :product_type].each do |type_att|
  
    define_method(type_att) do
      self.read_attribute(type_att).constantize
    end
  
    define_method("#{type_att}=") do |arg|
      self.write_attribute(type_att, arg.name)
    end
    
  end
  
  delegate   :billed_actor_type,  :to => :product_type
  delegate   :payed_actor_type,   :to => :product_type
  
  #defines the type applicable to, being one of: AwardedPromotion, GlobalPromotion, or GrantedAward
  validates_presence_of :apply_type
    
  def rule
    self.rule_type.load_from_data(self.rule_data)
  end
  
  def rule=(arg)
    if arg
      self.rule_type = arg.class
      self.rule_data = arg.rule_data
    else
      self.rule_type = nil
      self.rule_data = nil      
    end
  end
  
  def run(rule_monger)
    runner = RuleRunner.new(rule_monger.copy_of_the_facts)
    self.rule.run(runner)
    rule_monger.editable_facts.each do |k, v|
      rule_monger.editable_fact_update(k,runner.get(k))
    end
  end

end
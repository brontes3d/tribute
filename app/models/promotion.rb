class Promotion < ActiveRecord::Base

  include AuditCreatedByUser
  
  belongs_to :rule_definition
  validates_presence_of_association :rule_definition
  
  set_inheritance_column :promotion_type
  
  include IdGeneration
  
  [:product_type, :billed_actor_type, :payed_actor_type].each do |type_att|
    
    define_method(type_att) do
      self.read_attribute(type_att).constantize
    end
    
    define_method("#{type_att}=") do |arg|
      self.write_attribute(type_att, arg ? arg.name : nil)
    end
    
  end
  validate do |promotion|
    if rule_definition = promotion.rule_definition
      product_type = rule_definition.product_type
      promotion.product_type = product_type
      promotion.billed_actor_type = product_type.billed_actor_type
      promotion.payed_actor_type = product_type.payed_actor_type
    end
  end
  
  def run(rule_monger)
    rule = self.rule_definition
    facts_edited = 
      rule_monger.with_facts(
        :editable => {:usage_note => usage_note}
      ) do
        rule.run(rule_monger)
      end
    if facts_edited[:usage_note]
      self.usage_note = facts_edited[:usage_note]
      self.save!
    end
  end
  
end

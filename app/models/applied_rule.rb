class AppliedRule < ActiveRecord::Base
  
  belongs_to :applied_to_order, :class_name => "Order"
  
  belongs_to :rule, :polymorphic => true
  
  def name
    if self.rule
      self.rule.name
    else
      "?"
    end
  end
  
end
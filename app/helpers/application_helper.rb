# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def options_for_rule_selection(apply_type)
    RuleDefinition.find_all_by_apply_type(apply_type.to_s).select do |r|
      @billed_actor.class == r.billed_actor_type      
    end.collect do |r|
      [r.name, r.id]
    end
  end
  
end

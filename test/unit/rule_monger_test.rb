require File.dirname(__FILE__) + '/../test_helper'
require 'ostruct'

class RuleMongerTest < ActiveSupport::TestCase
  
  def test_rule_monger    
    invoice = OpenStruct.new({})
    rule_monger = RuleMonger.new(invoice)
    rule_monger.add_editable(:orders, [
        {'fees' => 1, 'free_stuff' => 0},
        {'fees' => 1, 'free_stuff' => 0}
    ])
    
    rule_monger.add_editable(:something_editable, 1)
    assert_raises(ArgumentError) do
      rule_monger.add_readbale(:something_editable, 1)    
    end
    
    rule_monger.add_readbale(:something_readable, 1)    
    assert_raises(ArgumentError) do
      rule_monger.add_editable(:something_readable, 1)    
    end
    
    assert_equal(['something_readable'], rule_monger.readable_keys)
    assert_equal(['orders', 'something_editable'].sort_by(&:to_s), rule_monger.editable_keys.sort_by(&:to_s))
    
    cs_rule1 = CodeStubRule.new("Rule 1")
    cs_rule1.rule_logic do
      replace_all('fees', 'free_stuff')
    end
    cs_rule2 = CodeStubRule.new("Rule 2")
    cs_rule2.rule_logic do
      @something_readable = count('free_stuff')
      @something_editable = count('free_stuff')
    end
    
    rule1 = RuleDefinition.new(:rule => cs_rule1)
    rule2 = RuleDefinition.new(:rule => cs_rule2)
    
    rule_monger.rules = [rule1, rule2]
    
    results = rule_monger.run!
    
    # puts "Results: " + results.inspect
    assert_equal({"something_editable"=>2, "orders"=>[{"free_stuff"=>1, "fees"=>0}, {"free_stuff"=>1, "fees"=>0}]}, results)
  end
  
end

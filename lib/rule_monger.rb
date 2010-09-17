class RuleMonger
  
  attr_reader :invoice, :editable_facts, :readable_facts
  
  def initialize(invoice)
    @invoice = invoice
    @editable_facts = {}
    @readable_facts = {}
    @rules_applied = []
  end
  
  def add_editable(key, value)
    if self.facts.key?(key.to_s)
      raise ArgumentError, "Already have a value for #{key}"
    end
    @editable_facts[key.to_s] = convert_value(value, true)
  end
  
  def editable_keys
    @editable_facts.keys
  end
  
  def editable_fact_update(key, value)
    unless self.editable_facts.key?(key.to_s)
      raise ArgumentError, "#{key} is not an editable fact"
    end
    previous_value = @editable_facts[key.to_s]    
    if previous_value != value && @current_rule_tracker
      @current_rule_tracker.notify_change(key.to_s, previous_value, value)
    end    
    @editable_facts[key.to_s] = value
  end
  
  def add_readbale(key, value)
    if self.facts.key?(key.to_s)
      raise ArgumentError, "Already have a value for #{key}"
    end
    @readable_facts[key.to_s] = convert_value(value, true)
  end
  
  def readable_keys
    @readable_facts.keys
  end
  
  def facts
    @readable_facts.merge(@editable_facts)
  end
  
  def copy_of_the_facts
    deep_dupe = Proc.new do |thing|
      if thing.is_a?(Array)
        thing.collect do |item|
          deep_dupe.call(item)
        end
      elsif thing.is_a?(Hash)
        to_return = thing.dup
        to_return.each do |k, v|
          to_return[k] = deep_dupe.call(v)
        end
        to_return
      else
        thing
      end
    end
    return deep_dupe.call(self.facts)
  end

  def with_facts(additional_facts)
    additional_readable_facts = additional_facts[:readable] || {}
    additional_readable_facts.each do |k, v|
      self.add_readbale(k, v)
    end
    additional_editable_facts = additional_facts[:editable] || {}
    additional_editable_facts.each do |k, v|
      self.add_editable(k, v)
    end
    yield
    to_return = {}
    additional_editable_facts.each do |k, v|
      new_value = @editable_facts[k.to_s]
      if v != new_value
        to_return[k] = new_value
      end
    end
    return to_return
  ensure
    additional_readable_facts.each do |k, v|
      @readable_facts.delete(k.to_s)
    end
    additional_editable_facts.each do |k, v|
      @editable_facts.delete(k.to_s)
    end
  end
  
  class RuleApplicationTracker
    attr_reader :changes, :rule
    def initialize(rule)
      @rule = rule
      @changes = {}
      @anything_changed = false
    end
    def notify_change(key, previous_value, value)
      @changes[key] = [previous_value, value]
    end    
    def anything_changed?
      !@changes.empty?
    end    
  end
  
  attr_reader :rules_applied
  def while_tracking_applications_of(rule)
    @current_rule_tracker = RuleApplicationTracker.new(rule)
    yield
  ensure
    if @current_rule_tracker.anything_changed?
      @rules_applied << @current_rule_tracker
    end
    @current_rule_tracker = nil
  end
  
  attr_accessor :rules
  
  def sorted_rules
    self.rules.sort do |r1, r2|
      if r1.respond_to?(:rule_definition) && r2.respond_to?(:rule_definition)
        r1.rule_definition.sort_order <=> r2.rule_definition.sort_order
      else
        0
      end
    end
  end
  
  def run!
    self.sorted_rules.each do |rule|
      while_tracking_applications_of(rule) do
        rule.run(self)
      end
    end
    self.editable_facts
  end
  
  private 
  
  def convert_value(value, editable = false)
    converted_value = nil
    if value.respond_to?(:readable_attributes)
      converted_value = value.readable_attributes
    end
    if editable && value.respond_to?(:editable_attributes)
      converted_value ||= {}
      converted_value = converted_value.merge(value.editable_attributes)      
    end
    converted_value ||= value
    if converted_value.is_a?(Array)
      return converted_value.collect{ |v| convert_value(v, editable) }
    end
    if converted_value.is_a?(Hash)
      to_return = {}
      converted_value.each do |k,v|
        to_return[k.to_s] = convert_value(v, editable)
      end
      return to_return
    end
    return converted_value
  end
  
end

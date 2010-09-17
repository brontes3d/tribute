class RuleRunner
  
  def initialize(facts)    
    facts.each do |k, value|
      self.instance_variable_set("@#{k}", value)
    end
  end
  
  def get(k)
    self.instance_variable_get("@#{k}")
  end
  
  def invoice_is_non_billable
    everything_is_non_billable
    @invoice_billable = false    
  end
  
  def everything_is_non_billable
    @orders.each do |order|
      order_is_non_billable(order)
    end
    true
  end
  
  def order_is_non_billable(order)
    SKU.skus.each do |k, v|
      if order[k]
        order[k] = 0
      end
    end      
    true
  end
  
  def count(look_for_thing_called)
    unless @orders
      return 0
    end
    count_found = 0
    @orders.each do |order|
      number_found = order[look_for_thing_called.to_s]
      if number_found && number_found > 0
        count_found += number_found
      end
    end
    count_found
  end
  
  def replace_all(replace_thing_called, with_thing_called)
    unless @orders
      return
    end
    @orders.each do |order|
      if number_found = order[replace_thing_called.to_s]
        if number_found > 0
          order[replace_thing_called.to_s] = 0
          order[with_thing_called.to_s] = number_found
        end
      end
    end
    true
  end
  
  def days_between(a, b)
    tz = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)")
    date_a = tz.parse(a.to_s)
    date_b = tz.parse(b.to_s)
    if !date_a || !date_b
      return 0
    end
    difference = (date_b - date_a)
    if difference < 0
      difference = (0 - difference)
    end
    to_return = (difference / 1.day)
    return to_return
  end
  
end

ActiveRecord::Base.class_eval do
  
  def self.han(val)
    self.human_attribute_name(val)
  end
  
end
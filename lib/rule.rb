class Rule
  
  cattr_accessor :code_stub_rules
  
  def self.load_code_stub_rules
    (self.code_stub_rules || []).each do |rule|
      rule.run_create_logic
    end
  end

  def self.load_rules
    Dir.new(File.join(RAILS_ROOT, "business", "rules")).each do |f|
      full_path = File.join(RAILS_ROOT, "business", "rules", f)
      unless File.directory?(full_path)
        require_dependency full_path
      end
    end
  end
  
  def self.load_from_data(rule_data)
    raise ArgumentError, "Rule Subclass #{self} needs to define load_from_data, given arg #{rule_data}"
  end
    
end
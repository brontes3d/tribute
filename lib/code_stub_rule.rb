class CodeStubRule < Rule
  
  def self.load_from_data(rule_data)
    self.find(rule_data)
  end
  def rule_data
    self.name
  end
  
  attr_reader :name
  
  def initialize(stub_name)
    @name = stub_name
    @@code_stubs ||= {}
    @@code_stubs[stub_name] = self
  end
  
  def self.find(stub_name)
    @@code_stubs ||= {}
    @@code_stubs[stub_name] or
      raise ArgumentError, "Couldn't find a CodeStubRule named #{stub_name}"
  end
  
  attr_accessor :manipulating
  
  def run(rule_runner)
    rule_runner.instance_eval(& self.logic )
  end
  
  def rule_logic(&block)
    @logic = block
    self
  end
  
  def logic
    @logic
  end
  
  def create_logic(&block)
    @create_logic = block
    Rule.code_stub_rules ||= []
    Rule.code_stub_rules << self
  end
  
  def run_create_logic
    @create_logic.call(self)
  end
  
end
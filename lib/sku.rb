class SKU
  
  def self.skus
    @@skus ||= {}
  end
  
  def self.lookup(named)
    self.skus[named.to_s]
  end
  
  attr_reader :name, :number
  def initialize(name, number)
    @name = name.to_s
    @number = number
    SKU.skus[name.to_s] = self
  end
  
  def self.ordered_each
    keys = self.skus.keys.sort_by{|k| skus[k].number }
    keys.each do |k|
      yield skus[k]
    end
  end
  
end
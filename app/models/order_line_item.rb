class OrderLineItem < ActiveRecord::Base
  
  belongs_to :order
  
  validates_presence_of :sku
  
  def sku
    SKU.lookup(self.sku_name)
  end
  
  def sku=(arg)
    if arg
      self.sku_name = arg.name
      self.sku_number = arg.number
    end
  end
  
end

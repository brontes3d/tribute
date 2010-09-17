class Order < ActiveRecord::Base
  
  has_many :order_line_items
  has_many :invoice_line_items
  has_many :applied_rules, :foreign_key => 'applied_to_order_id'
  
  belongs_to :product
  belongs_to :invoice
  
  validates_presence_of :product
  
  
  before_destroy :ensure_invoice_is_not_closed
  
  class ClosedInvoiceException < ArgumentError; end
  
  def ensure_invoice_is_not_closed
    if self.invoice.closed?
      raise ClosedInvoiceException, "Cannot delete order #{self.id} because it belongs to a closed invoice"
    end
  end
  
  def readable_attributes
    self.product.readable_attributes.merge(:id => self.id)
  end
  
  def editable_attributes
    @editable_attributes ||=
      (
      to_return = {}
      self.product.class.skus.each do |sku|
        number_of_sku = 0
        self.order_line_items.each do |line_item|
          if line_item.sku == sku
            number_of_sku += line_item.quantity
          end
        end
        to_return[sku.name] = number_of_sku
      end
      to_return      
      )
  end
  
  after_save :mark_invoice_for_update
  after_destroy :mark_invoice_for_update
  
  def mark_invoice_for_update
    self.invoice.dirty!
  end
    
end

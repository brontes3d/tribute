class Product < ActiveRecord::Base
  default_scope :order => 'name ASC'

  has_many :orders, :dependent => :destroy
  
  serialize :meta_data
  
  set_inheritance_column :product_type
  validates_presence_of :name
  validates_presence_of :posted_date
  
  include IdGeneration
  
  def readable_attributes
    to_return = (self.meta_data || {}).dup
    to_return[:name] = self.name
    to_return[:posted_date] = self.posted_date
    to_return
  end
  
  def self.load_types
    Dir.new(File.join(RAILS_ROOT, "business", "products")).each do |f|
      full_path = File.join(RAILS_ROOT, "business", "products", f)
      unless File.directory?(full_path)
        require_dependency full_path
      end
    end
  end
  
  def self.all_types
    @@all_types ||= {}
  end
  
  def self.inherited(by_class)
    by_class.class_eval do
      cattr_accessor :billed_actor_type, :payed_actor_type
      
      def self.belongs_to_billed(bill)
        self.billed_actor_type = bill.to_s.camelize.constantize
        belongs_to bill, :foreign_key => 'billed_actor_id', :class_name => self.billed_actor_type.to_s
        define_method("billed_actor") do
          self.send(bill)
        end
        validates_presence_of bill        
      end
      
      def self.belongs_to_payed(pay)
        self.payed_actor_type = pay.to_s.camelize.constantize
        belongs_to pay, :foreign_key => 'payed_actor_id', :class_name => self.payed_actor_type.to_s
        define_method("payed_actor") do
          self.send(pay)
        end        
        validates_presence_of pay
      end
      
      def self.meta_data_attribute(called, opts = {})
        opts[:writer] ||= Proc.new{ |arg| arg }
        opts[:reader] ||= Proc.new{ |arg| arg }
        define_method(called) do
          self.meta_data ||= {}
          opts[:reader].call(self.meta_data[called])
        end
        define_method("#{called}=") do |arg|
          self.meta_data ||= {}
          self.meta_data[called] = opts[:writer].call(arg)
        end
        if opts[:validate]
          validates_presence_of called
        end
      end
      
      cattr_accessor :skus
      def self.sku(name, number)
        self.skus ||= []
        self.skus << SKU.new(name, number)
      end
    end
    
    self.all_types[by_class.url_name] = by_class
    
    super(by_class)
  end
  
  def self.url_name
    self.name.underscore.pluralize
  end
  
  def each_posted_date
    yield self.posted_date, self.pricing_components
  end
  
  after_save :update_orders

  def update_orders
    Order.transaction do
      orders_regenerated = []
      self.each_posted_date do |posted_date, pricing_components|
          billing_cycle = BillingCycle.find_or_create_for_date(posted_date)        
          unless find_conflicting_order(billing_cycle)
            invoice = Invoice.find_or_create_invoice(:billed_actor => self.billed_actor, 
                                                     :payed_actor  => self.payed_actor, 
                                                     :posted_date  => posted_date)
            o = Order.find_by_product_id_and_invoice_id(self.id, invoice.id) ||
                Order.new(:product => self, :invoice => invoice)
            if invoice.closed? && o.new_record?
              invoice = invoice.find_or_create_next_open_invoice
              o.invoice = invoice
            end
            unless invoice.closed?
              unless self.orders.include?(o)
                self.orders << o
              end            
              existing_line_items = {}
              o.order_line_items.each{ |ol| existing_line_items[ol.sku] = ol.quantity }
              new_line_items = {}
              pricing_components.each do |k, v|
                if v.to_i > 0
                  sku = SKU.lookup(k)
                  new_line_items[sku] = v
                end
              end
              if self.changes_merit_order_regeneration?(existing_line_items, new_line_items)
                o.order_line_items.destroy_all
                new_line_items.each do |sku, quantity|
                  item = OrderLineItem.new(:quantity => quantity, 
                                           :sku => sku)
                  o.order_line_items << item
                end
                o.save!    
              end
              orders_regenerated << o
            end
          end
      end
      old_orders = (self.orders - orders_regenerated)
      old_orders.each do |old_order|
        old_order.destroy unless old_order.invoice.closed?
      end
    end
  end
  
  def changes_merit_order_regeneration?(existing_line_items, new_line_items)
    existing_line_items != new_line_items
  end
  
  private
  
  #find orders for the same product
  #where the order belongs to a closed invoice
  def find_conflicting_order(billing_cycle)
    Order.find_all_by_product_id(self.id, :include => 'invoice').detect do |order| 
      order.invoice.closed? &&
      (billing_cycle == order.invoice.billing_cycle)
    end
  end
  
end

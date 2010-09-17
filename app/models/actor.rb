class Actor < ActiveRecord::Base
  default_scope :order => 'actors.name ASC'
  
  set_inheritance_column :actor_type
  validates_presence_of :name
  
  has_many :granted_awards, :class_name => "GrantedAward", :foreign_key => 'billed_actor_id', :dependent => :destroy
  has_many :invoices_payed_to_me, :foreign_key => "payed_actor_id", :class_name => "Invoice", :dependent => :destroy
  
  has_many :invoices_billed_to_me, :foreign_key => "billed_actor_id", :class_name => "Invoice", :dependent => :destroy
  
  has_many :awarded_promotions, :foreign_key => "billed_actor_id", :class_name => "AwardedPromotion", :dependent => :destroy
  
  # belongs_to :earliest_dirty_invoice_billed_to_me, :class_name => "Invoice"
  has_one :dirty_invoice_marker, :foreign_key => 'billed_actor_id'
  
  include IdGeneration
  def self.id_generator_params
    {
      :number_adder => 10001, #first id generated will be 10001 + the check digit
      :number_prime => 1009,
      :scrambled_digits => 4 #1 fixed digit + 4 random-looking digits + 1 check digit      
    }
  end
  
  serialize :meta_data
  
  after_save :dirty_invoices
  def dirty_invoices
    (self.invoices_payed_to_me + self.invoices_billed_to_me).each do |invoice|
      if invoice.open? && !invoice.frozen?
        invoice.dirty!
      end
    end
  end
  
  def readable_attributes
    # (for rule's that reference this actor)
    if self.meta_data.blank?
      self.meta_data = {}
    end
    to_return = self.meta_data.dup
    to_return[:name] = self.name
    to_return
  end
  
  def self.load_types
    Dir.new(File.join(RAILS_ROOT, "business", "actors")).each do |f|
      full_path = File.join(RAILS_ROOT, "business", "actors", f)
      unless File.directory?(full_path)
        require_dependency full_path
      end
    end
  end
  
  def self.all_types
    @@all_types ||= {}
  end
  
  def self.inherited(by_class)
    self.all_types[by_class.url_name] = by_class
    by_class.class_eval do
      def self.meta_data_attribute(called, opts = {})
        opts[:writer] ||= Proc.new{ |arg| arg }
        define_method(called) do
          self.meta_data ||= {}
          self.meta_data[called]
        end
        define_method("#{called}=") do |arg|
          self.meta_data ||= {}
          old_val = self.meta_data[called]
          new_val = opts[:writer].call(arg)
          self.meta_data[called] = new_val
        end
        if opts[:validate]
          validates_presence_of called
        end
      end
    end
    super(by_class)
  end
  
  def self.url_name
    self.name.underscore.pluralize
  end
  
  def object_name_for_rules
    self.class.name.underscore
  end
  
  def get_redirect_to_url(controller)
    raise NotImplementedError, "subclass (#{self.class}) needs to define get_redirect_to_url"
  end
    
  def given_invoice_comes_before_earliest?(invoice)
    self.dirty_invoice_marker && self.dirty_invoice_marker.given_invoice_comes_before_earliest?(invoice)
  end
  
  def earliest_dirty_invoice_billed_to_me
    self.dirty_invoice_marker && self.dirty_invoice_marker.invoice
  end
      
end

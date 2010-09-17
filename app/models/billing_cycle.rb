class BillingCycle < ActiveRecord::Base
  
  has_many :invoices
  
  validates_presence_of :start_date
  validates_uniqueness_of :start_date
  validates_presence_of :end_date
  validates_uniqueness_of :end_date

  validates_presence_of :state
  
  validate do |billing_cycle|
    if Time.now < billing_cycle.end_date && billing_cycle.state == "closed"
      billing_cycle.errors.add(:state, "Cannot be closed because the end of the billing cycle has not yet passed")
    end
  end
  
  def name
    "#{I18n.l(self.start_date).strip} - #{I18n.l(self.end_date).strip}"
  end
  
  def self.get_range_for_date(date)
    date_with_zone = date.in_time_zone("Eastern Time (US & Canada)")
    return [date_with_zone.beginning_of_month, date_with_zone.end_of_month]
  end
  
  def self.create_for_date(date)
    start_date, end_date = BillingCycle.get_range_for_date(date)
    billing_cycle = BillingCycle.new(:start_date => start_date, :end_date => end_date, :state => 'open')
    billing_cycle.save!
    billing_cycle
  end
  
  def self.find_for_date(date)
    BillingCycle.find(:first, :conditions => 
                      [" ? BETWEEN start_date AND end_date", date.utc])
  end
  
  def self.find_first_open
    BillingCycle.find(:first, :conditions => "state = 'open'", :order => "start_date ASC")
  end
  
  def next
    BillingCycle.find_for_date(self.end_date + 1.day)
  end
  
  def self.find_or_create_for_date(date)
    billing_cycle = BillingCycle.find_for_date(date)
    unless billing_cycle
      begin
        billing_cycle = BillingCycle.create_for_date(date)
      rescue ActiveRecord::StatementInvalid => e
        BillingCycle.truly_in_seperate_transaction do
          billing_cycle = BillingCycle.find_for_date(date)
        end
      end
    end
    return billing_cycle
  end
  
  def self.time_for_month_year(month, year)
    ActiveSupport::TimeZone.new("Eastern Time (US & Canada)").parse("#{month}/2/#{year}")
  end
  
  def closed?
    self.state == "closed"
  end

  def open?
    !closed?
  end
  
  def close!
    BillingCycle.transaction do
      self.invoices.each do |i|
        if i.dirty?
          InvoiceRegenerator.regen_invoice(i)
          i.reload rescue ActiveRecord::RecordNotFound
        end
      end
      self.state = "closed"
      self.save!
    end 
    # ExportDispatcher.notify({'user' => User.current_user.user_number, 'billing_cycle' => self.id})
  end
  
  def self.choices_for_selection
    BillingCycle.all(:order => "billing_cycles.start_date ASC").collect do |bc|
      [bc.name, bc.id]
    end
  end
  
end
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class NewProductTest < ActiveSupport::TestCase
  
  context "with the current month's billing cycle closed" do
    setup do
      @billing_cycle = BillingCycle.find_or_create_for_date(Time.now - 6.months)
      @billing_cycle_start = @billing_cycle.start_date
      
      @dude = ThisDudeIsStoked.create!(:name => "Laird")
      @surf_shop = YourLocalSurfShop.create!(:name => "Zephyr")
      @stuff_this_month = StuffTheDudeCanBuy.create!(:posted_date => @billing_cycle_start + 1.day, 
                              :desired_board_type => "long",                               
                              :this_dude_is_stoked => @dude,
                              :your_local_surf_shop => @surf_shop)
      billing_cycle = @stuff_this_month.orders.first.invoice.billing_cycle
      billing_cycle.close!
    end
    
    should "accept new incoming orders for the current month and put them into the next open billing cycle" do
      @more_stuff_this_month = StuffTheDudeCanBuy.create!(:posted_date => @billing_cycle_start + 1.day, 
                                                          :desired_board_type => "short",      
                                                          :this_dude_is_stoked => @dude,
                                                          :your_local_surf_shop => @surf_shop)
      billing_cycle_found = @more_stuff_this_month.orders.first.invoice.billing_cycle
      billing_cycle_expected = BillingCycle.find_or_create_for_date(@billing_cycle.end_date + 1.day)
      assert_equal(billing_cycle_expected, billing_cycle_found)
    end
    
    context "and with the next 4 months of invoices closed" do
      setup do
        4.times do |n|
          @stuff_next_month = StuffTheDudeCanBuy.create!(
            :posted_date => (@billing_cycle.end_date + 1.day).advance(:months => n), 
            :desired_board_type => "short", :this_dude_is_stoked => @dude, :your_local_surf_shop => @surf_shop)
          billing_cycle = @stuff_next_month.orders.first.invoice.billing_cycle
          billing_cycle.close!
        end
      end
      
      should "still be able to place a new order today and have it find an open billing cycle for it" do
        @more_stuff_this_month = StuffTheDudeCanBuy.create!(:posted_date => @billing_cycle_start + 1.day, 
                                                            :desired_board_type => "short",      
                                                            :this_dude_is_stoked => @dude,
                                                            :your_local_surf_shop => @surf_shop)
        billing_cycle_found = @more_stuff_this_month.orders.first.invoice.billing_cycle
        billing_cycle_expected = BillingCycle.find_or_create_for_date((@billing_cycle.end_date + 1.day).advance(:months => 4))
        assert_equal(billing_cycle_expected, billing_cycle_found)
      end
      
    end
     
  end
  
end

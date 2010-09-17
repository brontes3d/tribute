require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class NewProductTest < ActiveSupport::TestCase
  
  context "with board orders in each 3 billing cycles" do
    setup do
      @billing_cycle = BillingCycle.find_or_create_for_date(Time.now - 6.months)
      @billing_cycle_start = @billing_cycle.start_date
      
      @dude = ThisDudeIsStoked.create!(:name => "Laird")
      @surf_shop = YourLocalSurfShop.create!(:name => "Zephyr")
      3.times do |n|
        StuffTheDudeCanBuy.create!(:posted_date => (@billing_cycle_start + 1.day).advance(:months => n), 
                                :desired_board_type => "long",
                                :number_of_t_shirts => 1,                            
                                :this_dude_is_stoked => @dude,
                                :your_local_surf_shop => @surf_shop)
      end
    end
    
    should "make messages for dirty invoices, and running those messages should clean everything" do
      @dude.reload
      @dude.invoices_billed_to_me.each do |inv|
        assert inv.dirty?
      end

      # puts @messages_sent.inspect
      run_all_messages

      @dude.reload
      @dude.invoices_billed_to_me.each do |inv|
        assert !inv.dirty?
      end
    end
    
    context "if invoice regeneration raises Mysql::Error: Deadlock, try again" do
      setup do
        Invoice.class_eval do
          def save!
            if defined?(@@save_bang_invoked) && @@save_bang_invoked
              super
            else
              @@save_bang_invoked = true
              raise ActiveRecord::StatementInvalid.new("Mysql::Error: Deadlock")
            end
          end
        end
      end
      teardown do
        Invoice.class_eval do
          @@save_bang_invoked = nil
          remove_method(:save!)
        end        
      end
      
      should "make messages for dirty invoices, and running those messages should clean everything" do
        @dude.reload
        @dude.invoices_billed_to_me.each do |inv|
          assert inv.dirty?
        end

        # puts @messages_sent.inspect
        run_all_messages

        @dude.reload
        @dude.invoices_billed_to_me.each do |inv|
          assert !inv.dirty?, "#{inv} is still dirty"
        end
      end
    end
    
    # context "when invoice is cleaned in one thread and made dirty in another" do
    #   setup do
    #     cleaner = Thread.new do
    #       run_all_messages
    #     end        
    #     dirty_maker = Thread.new do
    #       @dude.reload
    #       @dude.invoices_billed_to_me.first.regenerate
    #       p = StuffTheDudeCanBuy.find(:all).detect{ |stuff| stuff.this_dude_is_stoked == @dude }
    #       p.desired_board_type = "short"
    #       p.number_of_t_shirts = 2
    #       p.save!          
    #     end
    #   end
    #   
    #   should "both regenerate the invoice AND mark it as dirty" do
    #     
    #     flunk "TODO"
    #   end      
    # end
    
    context "when the earliest order is updated after the earliest invoice is regenerated" do
      setup do
        @dude.reload
        @dude.invoices_billed_to_me.first.regenerate
        p = StuffTheDudeCanBuy.find(:all).detect{ |stuff| stuff.this_dude_is_stoked == @dude }
        p.desired_board_type = "short"
        p.number_of_t_shirts = 2
        p.save!
      end
      
      should "be efficient in regenerating subsequent cycles (not regen the same invoice twice)" do
        @invoices_regenerated = []
        Invoice.after_save do |inv|
          if inv.changes['dirty'] && !inv.changes['dirty'][1]
            @invoices_regenerated << inv.invoice_number
          end
        end
        
        @dude.reload
        @dude.invoices_billed_to_me.each do |inv|
          assert inv.dirty?
        end

        # puts @messages_sent.inspect
        run_all_messages

        @dude.reload
        @dude.invoices_billed_to_me.each do |inv|
          assert !inv.dirty?
        end
        
        assert_equal(@invoices_regenerated.uniq, @invoices_regenerated, 
                    "Expected to only regenerate each invoice once #{@invoices_regenerated.inspect}")
      end
      
    end
     
  end
  
end

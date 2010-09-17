require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class InvoiceUniquenessTest < ActiveSupport::TestCase
  
  def setup
    super(:use_transactional => false)
    Invoice.destroy_all
    ThisDudeIsStoked.destroy_all
    YourLocalSurfShop.destroy_all
    @billing_cycle = BillingCycle.find_or_create_for_date(Time.now)
    @dude = ThisDudeIsStoked.create!(:name => "Laiiiird")
    @surf_shop = YourLocalSurfShop.create!(:name => "Zephyyyyr")
  end
      
  def test_retry
    t1output = Tempfile.new("InvoiceUniquenessTest")
    t1 = Process.fork do
      STDOUT.reopen(t1output.path)
      begin
        Invoice.connection.reconnect!
        Invoice.transaction do
          sleep(0.2)
          assert Invoice.find_or_create_invoice(:billed_actor => @dude, :payed_actor => @surf_shop,
                                :posted_date => @billing_cycle.start_date)
          sleep(0.3)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    t2output = Tempfile.new("InvoiceUniquenessTest")
    t2 = Process.fork do
      STDOUT.reopen(t2output.path)
      begin
        Invoice.connection.reconnect!
        Invoice.transaction do
          sleep(0.3)
          assert Invoice.find_or_create_invoice(:billed_actor => @dude, :payed_actor => @surf_shop,
                                :posted_date => @billing_cycle.start_date)
          sleep(0.2)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    Process.wait(t1)
    Process.wait(t2)
    
    invoices = Invoice.find(:all, :conditions => [
        "billed_actor_id = ? AND payed_actor_id = ? AND billing_cycle_id = ? ", 
        @dude.id, @surf_shop.id, @billing_cycle.id])
        
    combined_proc_run_output = t1output.read + t2output.read
    
    # puts combined_proc_run_output
      
    assert_equal(1, invoices.size, 
      "Expected to create only one invoice but got: #{invoices.inspect}")
    
    assert_equal("", combined_proc_run_output)    
  end
  
  def test_uniquness
    t1output = Tempfile.new("InvoiceUniquenessTest")
    t1 = Process.fork do
      STDOUT.reopen(t1output.path)
      begin
        Invoice.connection.reconnect!
        Invoice.transaction do
          sleep(0.2)
          Invoice.create!(:billed_actor => @dude, :payed_actor => @surf_shop,
                                :billing_cycle => @billing_cycle,
                                :dirty_version => 1, :clean_version => 0)
          sleep(0.3)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    t2output = Tempfile.new("InvoiceUniquenessTest")
    t2 = Process.fork do
      STDOUT.reopen(t2output.path)
      begin
        Invoice.connection.reconnect!
        Invoice.transaction do
          sleep(0.3)
          Invoice.create!(:billed_actor => @dude, :payed_actor => @surf_shop,
                                :billing_cycle => @billing_cycle,
                                :dirty_version => 1, :clean_version => 0)
          sleep(0.2)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    Process.wait(t1)
    Process.wait(t2)
    
    invoices = Invoice.find(:all, :conditions => [
        "billed_actor_id = ? AND payed_actor_id = ? AND billing_cycle_id = ? ", 
        @dude.id, @surf_shop.id, @billing_cycle.id])
        
    combined_proc_run_output = t1output.read + t2output.read
    
    # puts combined_proc_run_output
        
    assert_equal(1, invoices.size, 
      "Expected to create only one invoice but got: #{invoices.inspect}")
    
    assert combined_proc_run_output.index("ActiveRecord::StatementInvalid: Mysql::Error: Duplicate entry"), 
        "Expected one of the proc to raise exception about duplicate entry but got: \n" + combined_proc_run_output
  end
  
end

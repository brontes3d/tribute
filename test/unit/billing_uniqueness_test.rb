require File.dirname(__FILE__) + '/../test_helper'

class BillingUniquenessTest < ActiveSupport::TestCase
  
  def setup
    super(:use_transactional => false)
    BillingCycle.destroy_all
  end
  
  def test_retry
    date = Time.now
    t1output = Tempfile.new("BillingUniquenessTest")
    t1 = Process.fork do
      STDOUT.reopen(t1output.path)
      begin
        BillingCycle.connection.reconnect!
        BillingCycle.transaction do
          sleep(0.2)
          assert BillingCycle.find_or_create_for_date(date)
          sleep(0.3)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    t2output = Tempfile.new("BillingUniquenessTest")
    t2 = Process.fork do
      STDOUT.reopen(t2output.path)
      begin
        BillingCycle.connection.reconnect!
        BillingCycle.transaction do
          sleep(0.3)
          assert BillingCycle.find_or_create_for_date(date)          
          sleep(0.2)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    Process.wait(t1)
    Process.wait(t2)
    bcs = BillingCycle.find(:all, :conditions => 
                      [" ? BETWEEN start_date AND end_date", date.utc])
    
    combined_proc_run_output = t1output.read + t2output.read
    
    # puts combined_proc_run_output
    
    assert_equal(1, bcs.size,
      "Expected to create only one billing cycle but got: #{bcs.inspect}")
      
    assert_equal("", combined_proc_run_output)    
  end
  
  def test_uniquness
    date = Time.now
    t1output = Tempfile.new("BillingUniquenessTest")
    t1 = Process.fork do
      STDOUT.reopen(t1output.path)
      begin
        BillingCycle.connection.reconnect!
        BillingCycle.transaction do
          sleep(0.2)
          BillingCycle.create_for_date(date)
          sleep(0.3)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    t2output = Tempfile.new("BillingUniquenessTest")
    t2 = Process.fork do
      STDOUT.reopen(t2output.path)
      begin
        BillingCycle.connection.reconnect!
        BillingCycle.transaction do
          sleep(0.3)
          BillingCycle.create_for_date(date)          
          sleep(0.2)
        end
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end
    Process.wait(t1)
    Process.wait(t2)
    bcs = BillingCycle.find(:all, :conditions => 
                      [" ? BETWEEN start_date AND end_date", date.utc])
    
    combined_proc_run_output = t1output.read + t2output.read
    
    # puts combined_proc_run_output
    
    assert_equal(1, bcs.size, 
      "Expected to create only one billing cycle but got: #{bcs.inspect}")

    assert combined_proc_run_output.index("ActiveRecord::StatementInvalid: Mysql::Error: Duplicate entry"), 
        "Expected one of the proc to raise exception about duplicate entry but got: \n" + combined_proc_run_output
  end
  
end

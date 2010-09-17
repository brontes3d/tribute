class BillingCycleUniqueIndex < ActiveRecord::Migration
  def self.up
    add_index :billing_cycles, [:start_date, :end_date], :unique => true
  end

  def self.down
    remove_index :billing_cycles, [:start_date, :end_date]
  end
end

class AddAppliedToOrderIdIndex < ActiveRecord::Migration
  def self.up
    add_index :applied_rules, :applied_to_order_id
  end

  def self.down
    remove_index :applied_rules, :applied_to_order_id
  end
end

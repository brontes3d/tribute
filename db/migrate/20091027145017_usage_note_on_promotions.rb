class UsageNoteOnPromotions < ActiveRecord::Migration
  def self.up
    add_column :promotions, :usage_note, :text
  end

  def self.down
    remove_column :promotions, :usage_note
  end
end

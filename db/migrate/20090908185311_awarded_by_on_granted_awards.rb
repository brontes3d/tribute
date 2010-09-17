class AwardedByOnGrantedAwards < ActiveRecord::Migration
  
  def self.up
    add_column :granted_awards, :awarded_by_username, :string
  end

  def self.down
    remove_column :granted_awards, :awarded_by_username
  end
  
end

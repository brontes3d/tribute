class ActorUniqueIndex < ActiveRecord::Migration
  def self.up
    add_index :actors, [:name], :unique => true
  end

  def self.down
    remove_index :actors, [:name]
  end
end

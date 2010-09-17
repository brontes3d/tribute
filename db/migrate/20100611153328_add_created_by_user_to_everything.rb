class AddCreatedByUserToEverything < ActiveRecord::Migration
  def self.up
    add_column :granted_awards, :created_by_username, :string
    add_column :promotions, :created_by_username, :string
    add_column :actors, :created_by_username, :string
    add_column :products, :created_by_username, :string
    
    add_column :granted_awards, :created_by_user_number, :integer
    add_column :promotions, :created_by_user_number, :integer
    add_column :actors, :created_by_user_number, :integer
    add_column :products, :created_by_user_number, :integer
  end

  def self.down
    remove_column :granted_awards, :created_by_username
    remove_column :promotions, :created_by_username
    remove_column :actors, :created_by_username
    remove_column :products, :created_by_username
    
    remove_column :granted_awards, :created_by_user_number
    remove_column :promotions, :created_by_user_number
    remove_column :actors, :created_by_user_number
    remove_column :products, :created_by_user_number
  end
end

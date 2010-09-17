require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class IdGenTest < ActiveSupport::TestCase
  
  #just make sure the id gen decs are valid and that accounts and products can be made...
  def test_id_gen
    10.times do |n|
      dude = ThisDudeIsStoked.create!(:name => "Laird#{n}")
      surf_shop = YourLocalSurfShop.create!(:name => "Zephyr#{n}")
      stuff_this_month = StuffTheDudeCanBuy.create!(:posted_date => Time.now, 
                              :desired_board_type => 'long',
                              :this_dude_is_stoked => dude,
                              :your_local_surf_shop => surf_shop)
      # puts "#{dude.actor_number} -- #{n}"
      # puts surf_shop.actor_number
      # puts stuff_this_month.product_number
    end
  end
  
end

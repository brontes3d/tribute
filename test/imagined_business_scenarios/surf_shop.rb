ApplicationController.class_eval do
  def say_message
    render :text => params[:message]
  end
end

class YourLocalSurfShop < Actor
  
end

class ThisDudeIsStoked < Actor
  
  def get_redirect_to_url(controller)
    controller.url_for(:controller => 'application', :action => 'say_message', :message => self.name)
  end
  
end

class StuffTheDudeCanBuy < Product
  
  belongs_to_billed :this_dude_is_stoked
  belongs_to_payed :your_local_surf_shop
  
  meta_data_attribute :desired_board_type, :validate => true
  meta_data_attribute :number_of_t_shirts, :writer => Proc.new(&:to_i)
  
  sku :surfboard, "hang-10"
  sku :leash, "11"
  sku :wax, "1"
  sku :t_shirt, "15"
  
  def name
    "Buying a #{self.desired_board_type}"
  end
  
  def pricing_components
    {
      :surfboard => 1,
      :t_shirt => self.number_of_t_shirts
    }
  end
  
end

#code stub rules:
CodeStubRule.new("Free T-shirts").rule_logic do
  puts "TODO: free t-shirt!"
end

CodeStubRule.new("Free surf wax").rule_logic do
  puts "TODO: free wax!"
end

CodeStubRule.new("Free T-Shirt with Board").rule_logic do
  puts "TODO: free shirt with board!"
end

#available rules for granted awards:

#free t-shirt
free_t_shirt = RuleDefinition.find_by_name("Free T-shirts") ||
               RuleDefinition.create!(:name => "Free T-shirts",
                                     :sort_order => 50,
                                     :active => true,
                                     :product_type => StuffTheDudeCanBuy, 
                                     :apply_type => GrantedAward,
                                     :rule => CodeStubRule.find("Free T-shirts"))

#free wax
free_wax = RuleDefinition.find_by_name("Free surf wax") ||
           RuleDefinition.create!(:name => "Free surf wax",
                                     :sort_order => 51,
                                     :active => true,
                                     :product_type => StuffTheDudeCanBuy, 
                                     :apply_type => GrantedAward,
                                     :rule => CodeStubRule.find("Free surf wax"))

free_tshirt_with_board = RuleDefinition.find_by_name("Free T-Shirt with Board") ||
                         RuleDefinition.create!(:name => "Free T-Shirt with Board",
                                                :sort_order => 1,
                                                :active => true,
                                                :product_type => StuffTheDudeCanBuy, 
                                                :apply_type => AwardedPromotion,
                                                :rule => CodeStubRule.find("Free T-Shirt with Board"))


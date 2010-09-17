require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class AwardedPromotionsControllerTest < ActionController::IntegrationTest
  
  def test_awarded_promotions_created_by_user
    @dude = ThisDudeIsStoked.create!(:name => "Just bought a board")    
    visit url_for(:action => 'new', :controller => 'awarded_promotions', :billed_actor_id => @dude, :locale => 'en')
    select "Free T-Shirt with Board", :from => 'awarded_promotion_rule_definition_id'
    click_button "Create"
    assert_response 200, "Expected 200 but got #{@response.body}"    
    @dude.reload
    awarded_promotion = @dude.awarded_promotions.first
    
    assert_equal awarded_promotion.created_by_username, User.current_user.username
    assert_equal awarded_promotion.created_by_user_number, User.current_user.user_number
  end
  
  def test_awarded_promotions_scenarios
    @dude = ThisDudeIsStoked.create!(:name => "Just bought a board")
    
    #test 'new' view with and without a passed in 'billed_actor_id'.. should show drop-down or just hidden field
    
    get url_for(:action => 'new', :controller => 'awarded_promotions', :locale => 'en')
    assert_response 404, "Expected 404 but got #{@response.body}"
    
    visit url_for(:action => 'new', :controller => 'awarded_promotions', :billed_actor_id => @dude, :locale => 'en')
    assert_contain(/Grant To.*\s*.*Just bought a board/)
    
    click_button "Create"    
    
    assert_contain(/Grant To.*\s*.*Just bought a board/)
    assert_have_selector '.fieldWithErrors select#awarded_promotion_rule_definition_id'
    
    #should only see RuleDefinitions of type AwardedPromotion, which can be granted to ThisDudeIsStoked
    assert_select "select#awarded_promotion_rule_definition_id"
    elems = assert_select "select#awarded_promotion_rule_definition_id option"
    actual_options_found = 0
    elems.each do |elem|
      found_option_called = elem.children[0].to_s
      unless found_option_called.blank?
        actual_options_found += 1
        rule_def = RuleDefinition.find_by_name(found_option_called)
        assert rule_def, "since there is a selectable option called #{found_option_called} "+
                         "we expected to find a rule with same name"
        assert_equal AwardedPromotion, rule_def.apply_type, 
                     "Expected to only be able to select rules of type GrantedAward"
        assert_equal ThisDudeIsStoked, rule_def.billed_actor_type,
                      "Expected to only be able to select rules with billed_actor_type of ThisDudeIsStoked"
      end
    end
    assert_equal(1, actual_options_found, "Expected 1 option but got #{elems.to_s}")
    
    select "Free T-Shirt with Board", :from => 'awarded_promotion_rule_definition_id'
    click_button "Create"

    assert_response 200, "Expected 200 but got #{@response.body}"

    #test redirection... after award created, updated, or destroyed, should redirect to 'get_redirect_to_url' 
    # which should be generated from billed_actor.get_redirect_to_url
    assert_equal("Just bought a board", @response.body, 
                    "Expected response to be 'Just bought a board' as evidence that we redirected to the "+
                    "get_redirect_to_url gotten from the ThisDudeIsStoked instance")
    
    @dude.reload
    awarded_promotion = @dude.awarded_promotions.first
    
    assert_equal(RuleDefinition.find_by_name("Free T-Shirt with Board"), awarded_promotion.rule_definition)
    
    get url_for(:controller => 'awarded_promotions', :action => 'edit', :id => awarded_promotion, :locale => 'en')
    assert_response 404, "Expected 404 but got #{@response.body}"
  end
  
        
end

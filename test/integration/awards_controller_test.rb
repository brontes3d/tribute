require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../imagined_business_scenarios/surf_shop'

class AwardsControllerTest < ActionController::IntegrationTest
  
  def test_created_by_user
    User.current_user=User.new(:username => "bob", :user_number => 1)
    @bob = ThisDudeIsStoked.create!(:name => "Bob")
    
    visit url_for(:action => 'new', :controller => 'awards', :billed_actor_id => @bob, :locale => 'en')
    click_button "Create"    
    fill_in "award_quantity_awarded", :with => "2"
    select "2008", :from => "award_start_date_1i"
    select "August", :from => "award_start_date_2i"
    select "2009", :from => "award_end_date_1i"
    select "September", :from => "award_end_date_2i"    
    select "Free surf wax", :from => 'award_rule_definition_id'
    click_button "Create"
    assert_response 200, "Expected 200 but got #{@response.body}"
    @bob.reload
    created_award = @bob.granted_awards.first
    
    assert_equal created_award.created_by_username, User.current_user.username
    assert_equal created_award.created_by_user_number, User.current_user.user_number
  end
  
  def test_awards_scenarios
    @bob = ThisDudeIsStoked.create!(:name => "Bob")

    #test 'new' view with and without a passed in 'billed_actor_id'.. should show drop-down or just hidden field

    get url_for(:action => 'new', :controller => 'awards', :locale => 'en')
    assert_response 404, "Expected 404 but got #{@response.body}"

    visit url_for(:action => 'new', :controller => 'awards', :billed_actor_id => @bob, :locale => 'en')
    click_button "Create"
    
    assert_have_selector '.fieldWithErrors input#award_quantity_awarded'
    assert_have_selector '.fieldWithErrors select#award_rule_definition_id'
    
    # we could only test this if we allow blanks for selection of start_date and end_date
    # select "", :from => "award_start_date_1i"
    # select "", :from => "award_start_date_2i"
    # select "", :from => "award_end_date_1i"
    # select "", :from => "award_end_date_2i"
    # assert_have_selector 'div.fieldWithErrors select#award_start_date_1i'
    # assert_have_selector 'div.fieldWithErrors select#award_start_date_2i'
    # assert_have_selector 'div.fieldWithErrors select#award_end_date_1i'
    # assert_have_selector 'div.fieldWithErrors select#award_end_date_2i'
    # #should be errors on dates, quantity awarded and rule selected    
    
    fill_in "award_quantity_awarded", :with => "2"

    select "2008", :from => "award_start_date_1i"
    select "August", :from => "award_start_date_2i"
    select "2009", :from => "award_end_date_1i"
    select "September", :from => "award_end_date_2i"

    #should only see RuleDefinitions of type GrantedAward, which can be granted to ThisDudeIsStoked
    assert_select "select#award_rule_definition_id"
    elems = assert_select "select#award_rule_definition_id option"
    actual_options_found = 0
    elems.each do |elem|
      found_option_called = elem.children[0].to_s
      unless found_option_called.blank?
        actual_options_found += 1
        rule_def = RuleDefinition.find_by_name(found_option_called)
        assert rule_def, "since there is a selectable option called #{found_option_called} "+
                         "we expected to find a rule with same name"
        assert_equal GrantedAward, rule_def.apply_type, 
                     "Expected to only be able to select rules of type GrantedAward"
        assert_equal ThisDudeIsStoked, rule_def.billed_actor_type,
                      "Expected to only be able to select rules with billed_actor_type of ThisDudeIsStoked"
      end
    end
    assert_equal(2, actual_options_found, "Expected 2 options but got #{elems.to_s}")
    
    select "Free surf wax", :from => 'award_rule_definition_id'
    click_button "Create"

    assert_response 200, "Expected 200 but got #{@response.body}"

    #test redirection... after award created, updated, or destroyed, should redirect to 'get_redirect_to_url' 
    # which should be generated from billed_actor.get_redirect_to_url
    assert_equal("Bob", @response.body, 
                    "Expected response to be just 'Bob' as evidence that we redirected to the "+
                    "get_redirect_to_url gotten from the ThisDudeIsStoked instance")
        
    #test 'edit' view, shouldn't be able to change actor or rule
    @bob.reload
    created_award = @bob.granted_awards.first
    
    # test date entry, selection of start and end dates should be year/month only:
    # august 2009 start date should == august 1st 0:00 EST 2009
    # august 2009 end date should == august 31st 23:59 EST 2009    
    tz = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)")
    assert_equal(tz.parse("01 Aug 2008 00:00:00"), created_award.start_date)
    assert_equal(tz.parse("30 Sep 2009 23:59:59"), created_award.end_date)
    
    visit url_for(:controller => 'awards', :action => 'edit', :id => created_award, :locale => 'en')
    
    assert_contain(/Grant To.*Bob/)
    assert_contain(/Using Rule.*Free surf wax/)
    
    assert_equal("2008",
        assert_select("select#award_start_date_1i option[selected=selected]")[0].children[0].to_s)
    assert_equal("August",
        assert_select("select#award_start_date_2i option[selected=selected]")[0].children[0].to_s)
    assert_equal("2009",
        assert_select("select#award_end_date_1i option[selected=selected]")[0].children[0].to_s)
    assert_equal("September",
        assert_select("select#award_end_date_2i option[selected=selected]")[0].children[0].to_s)
    
    #should not be able to change the rule on edit
    assert_have_no_selector("select#award_rule_definition_id")    
    assert_select "input#award_quantity_awarded", :value => 2
    
    #TODO: fixme:
    
    # click_button "Save"
    # assert_response 200, "Expected 200 but got #{@response.body}"
    # 
    # #test redirection... after award created, updated, or destroyed, should redirect to 'get_redirect_to_url' 
    # # which should be generated from billed_actor.get_redirect_to_url
    # assert_equal("Bob", @response.body, 
    #                 "Expected response to be just 'Bob' as evidence that we redirected to the "+
    #                 "get_redirect_to_url gotten from the ThisDudeIsStoked instance")
  end
  
        
end

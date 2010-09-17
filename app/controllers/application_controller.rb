# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#TODO: this should be here during development so it always reloads, but in prod it should only run once
# LadyTribute.load_business
require_dependency 'lady_tribute'

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  def default_url_options(options={})
    if options[:locale].is_a?(ActiveRecord::Base)
      options[:id] = options[:locale]
    end
    {:locale => I18n.locale}
  end
  
  before_filter :set_time_zone
  
  def set_time_zone
    Time.zone = "Eastern Time (US & Canada)"
  end
  
  # rescue exceptions
  rescue_from Exception do |ex|
    render_error_response(ex)
  end
  
  def render_error_response(exception)
    if request.xhr?
      logger.error(exception.to_s + exception.backtrace.join("\n"))
    end
    # Comment out this line to test the exception responses that would be seen in production
    rescue_action_locally(exception) and return if consider_all_requests_local || local_request?    

    status_to_use = ActionController::Base.rescue_responses[exception.class.name]    
    exception_message_for_client = exception.message
    if exception.is_a?(ActiveRecord::StatementInvalid) or exception_message_for_client.index("Mysql::Error")
      exception_message_for_client = "A Database Error has occurred"
    end    
    respond_to do |format|
      format.html do
        if status_to_use == :not_found
          render :file => "#{RAILS_ROOT}/public/404.html", :status => status_to_use
        else
          render :file => "#{RAILS_ROOT}/public/500.html", :status => status_to_use
        end
      end
    end
  end
  
end

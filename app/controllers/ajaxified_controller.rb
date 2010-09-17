class AjaxifiedController < InheritedResources::Base
  
  def show
    super(&format_proc)
  end
  
  def new
    super(&format_proc)
  end
  
  def edit
    super(&format_proc)
  end
  
  def update
    super(&action_format_proc('show', 'edit'))
  end
  
  def create
    super(&action_format_proc('show', 'new'))
  end
  
  protected
  
  def action_format_proc(succcess_action, failure_action)
    Proc.new do |success, failure|
      if request.xhr?
        success.html{ render_redirect }
        failure.html{ render :action => failure_action, :layout => false }
      else
        success.html{ redirect_to get_redirect_to_url }
        failure.html{ render :action => failure_action }        
      end
    end
  end
  
  def get_redirect_to_url
    if resource.respond_to?(:get_redirect_to_url)
      resource.get_redirect_to_url(self)
    else
      url_for(:action => 'show', :id => resource)
    end    
  end
  
  def format_proc
    Proc.new do |format|
      format.html do
        if request.xhr?
          render :action => action_name, :layout => false
        else
          render :action => action_name
        end
      end      
    end
  end
  
  def render_redirect
    render :text => %Q{
      <script type="text/javascript">      
        window.location = "#{get_redirect_to_url}";
      </script>
    }
  end
end
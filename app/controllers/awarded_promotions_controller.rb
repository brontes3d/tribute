class AwardedPromotionsController < AjaxifiedController
  resourceful_views_theme :panel_browser
  
  actions :new, :destroy, :create
  
  def new
    if params[:billed_actor_id]
      @billed_actor = Actor.find_by_to_param(params[:billed_actor_id])
    end
    unless @billed_actor
      raise ActiveRecord::RecordNotFound, "Couldn't find billed actor #{params[:billed_actor_id]}"
    end
    super
  end
  
  def edit
    raise ActiveRecord::RecordNotFound, "Edit not allowed"
  end
  
  #TODO: only allow destroy if not used on any closed invoices  
  def destroy
    destroy! do |format|
      format.html{ redirect_to @awarded_promotion.get_redirect_to_url(self) }
    end
  end
  
end
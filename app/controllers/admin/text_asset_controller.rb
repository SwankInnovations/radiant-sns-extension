class Admin::TextAssetController < Admin::AbstractModelController

  def initialize
    super
    @cache = TextAssetResponseCache.instance
  end

  def new
    self.model = model_class.new
    render :action => "edit" if handle_new_or_edit_post
  end

  def remove
    self.model = model_class.find(params[:id])
    if request.post?
      model.destroy
      announce_removed
      clear_model_cache
      redirect_to model_index_url # <-- Added this line to clear cache on remove
    end
  end

end
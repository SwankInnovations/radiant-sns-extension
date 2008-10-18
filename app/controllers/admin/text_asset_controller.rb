class Admin::TextAssetController < Admin::AbstractModelController

  def initialize()
    super
    # overwrite @cache from super with our special cache
    @cache = TextAssetResponseCache.instance
  end


  def index
    # we CANNOT use the plural 'self.models' as this creates a @stylesheets
    # instance variable which conflictss with Radiants admin @stylesheets
    @text_assets = self.model = model_class.find(:all)
    # force child controllers to render template in the admin/text_asset directory
    render :template => "admin/text_asset/index", :object => @model_name = model_name
  end


  def new
    @text_asset = self.model = model_class.new
    # force child controllers to render template in the admin/text_asset directory
    render :template => "admin/text_asset/edit" if handle_new_or_edit_post
  end


  def edit
    @text_asset = self.model = model_class.find_by_id(params[:id])
    # force child controllers to render template in the admin/text_asset directory
    render :template => "admin/text_asset/edit" if handle_new_or_edit_post
  end


  def remove
    @text_asset = self.model = model_class.find(params[:id])
    if request.post?
      model.destroy
      announce_removed
      clear_model_cache # <-- Added this line to clear cache on remove
      redirect_to model_index_url
    else
      # force child controllers to render template in the admin/text_asset directory
      render :template => "admin/text_asset/remove"
    end
  end

end
class Admin::TextAssetController < Admin::AbstractModelController

  only_allow_access_to :index, :new, :edit, :remove,
    :when => [:developer, :admin],
    :denied_url => { :controller => 'page', :action => 'index' },
    :denied_message => 'You must have developer or administrator privileges to perform this action.'

  before_filter :set_model


  def initialize()
    super
    # overwrite @cache from super with our special cache
    @cache = TextAssetResponseCache.instance
  end


  def index
    # we CANNOT use the plural 'self.models' as this creates a @stylesheets
    # instance variable which conflictss with Radiants admin @stylesheets
    @text_assets = self.model = model_class.find(:all)
    @model_name = model_name
  end


  def new
    @text_asset = self.model = model_class.new
    # force child controllers to render template in the admin/text_asset directory
    render :action => :edit if handle_new_or_edit_post
  end


  def edit
    @text_asset = self.model = model_class.find_by_id(params[:id])
    handle_new_or_edit_post
  end


  def remove
    @text_asset = self.model = model_class.find(params[:id])
    if request.post?
      model.destroy
      announce_removed
      clear_model_cache # <-- Added this line to clear cache on remove
      redirect_to model_index_url
    end
  end


  def upload
    if !request.post?  # not a POST request
      render :template => "site/not_found", :status => :method_not_allowed

    elsif params[:upload].nil?  # necessary params are missing
      render :text => '', :status => :bad_request

    else
      @text_asset = model_class.create_from_file(params[:upload][:file])

      if @text_asset.new_record?  # wasn't saved -- there must be errors
        responds_to_parent do
          render :update do |page|
            # populate errors in the errors popup and call method to show
            page.replace_html "errors_for_#{model_name}", 
                '<ul class="uploadErrors">' + 
                @text_asset.errors.collect{|k,v| 
                  %{<li class="warning">#{k.humanize.titlecase}: #{v}</li>}
                }.to_s +
                '</ul>'
            page.call('showErrorsPopup')
          end
        end

      else  # success!
        responds_to_parent do
          render :update do |page| 
            page.redirect_to(:action => 'index')
          end
        end

      end

    end
  end


  private

    # since the model name comes from the params, the model_class cannot
    # be set until after initialization (seems like params are only available
    # to the action methods).  So we'll process 'em as part of a before_filter
    def set_model
      self.class.model_class params[:asset_type].camelize.constantize
    end

end
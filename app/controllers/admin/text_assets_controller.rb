class Admin::TextAssetsController < Admin::ResourceController

  only_allow_access_to :index, :new, :edit, :remove, :upload,
    :when => [:developer, :admin],
    :denied_url => { :controller => 'pages', :action => 'index' },
    :denied_message => 'You must have developer or administrator privileges to perform this action.'

  prepend_before_filter :set_model

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
            page.replace_html "errors_for_#{model_symbol}",
                '<ul class="uploadErrors">' +
                @text_asset.errors.collect{|k,v|
                  %{<li class="warning">#{k.humanize.titlecase}: #{v}</li>}
                }.to_s +
                '</ul>'
            page.call('showErrorsPopup')
          end
        end

      else  # success!
        # AbstractController methods aren't available within parent/render
        # blocks so call #model_index_url now to use from inside
        index_url = send("admin_#{model_symbol}s_url")
        responds_to_parent do
          render :update do |page|
            page.redirect_to index_url
          end
        end

      end

    end
  end

  protected

    # we CANNOT use the plural as this creates a @stylesheets
    # instance variable which conflicts with Radiant's admin @stylesheets
    def models
      instance_variable_get("@#{model_symbol}") || load_models
    end

    def models=(objects)
      instance_variable_set("@#{model_symbol}", objects)
    end

  private

    # since the model name comes from the params, the model_class cannot
    # be set until after initialization (seems like params are only available
    # to the action methods).  So we'll process 'em as part of a before_filter
    def set_model
      self.class.instance_variable_set "@model_class", params[:asset_type].camelize.constantize
    end

end

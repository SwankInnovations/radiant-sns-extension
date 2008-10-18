class JavascriptsScenario < Scenario::Base

  def load
    create_js_asset "main.js", :raw_content => 'Main js_asset content'
  end

  helpers do
    def create_js_asset(filename, attributes={})
      create_model :js_asset, 
                    filename.symbolize,
                    js_asset_params(attributes.reverse_merge(:filename => filename))
    end
    
    def js_asset_params(attributes={})
      filename = attributes[:filename] || unique_js_asset_filename
      { 
        :filename => filename,
        :raw_content => "dummy content"
      }.merge(attributes)
    end

    # the built-in scenario helper methods only deal with the root class (i.e.
    # the one with the table -- text_asset).  So we just build our own versions.
    #
    # NOTE: There must be no symbolic naming conflics between child classes (so
    # the Stylesheets scenario and Javascripts scenario can't both have a :main
    # That's ok since we're using :main_css and :main_js naming rules here.
    def js_assets(symbolic_name)
      text_assets(symbolic_name)
    end

    def js_asset_id(symbolic_name)
      text_asset_id(symbolic_name)
    end

    private
    
      @@unique_js_asset_filename_call_count = 0

      def unique_js_asset_filename
        @@unique_js_asset_filename_call_count += 1
        "js_asset-#{@@unique_js_asset_filename_call_count}.js"
      end

  end

end
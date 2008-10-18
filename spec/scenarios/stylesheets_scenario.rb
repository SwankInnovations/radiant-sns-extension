class StylesheetsScenario < Scenario::Base

  def load
    create_css_asset "main.css", :raw_content => "Main css_asset content"
  end

  helpers do
    def create_css_asset(filename, attributes={})
      create_model :css_asset, 
                    filename.symbolize,
                    css_asset_params(attributes.reverse_merge(:filename => filename))
    end
    
    def css_asset_params(attributes={})
      filename = attributes[:filename] || unique_css_asset_filename
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
    def css_assets(symbolic_name)
      text_assets(symbolic_name)
    end

    def css_asset_id(symbolic_name)
      text_asset_id(symbolic_name)
    end

    private
    
      @@unique_css_asset_filename_call_count = 0

      def unique_css_asset_filename
        @@unique_css_asset_filename_call_count += 1
        "css_asset-#{@@unique_css_asset_filename_call_count}.css"
      end

  end

end
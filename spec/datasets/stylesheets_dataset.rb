class StylesheetsDataset < Dataset::Base

  def load
    create_stylesheet "main", :content => "Main stylesheet content"
  end


  helpers do

    def create_stylesheet(name, attributes={})
      create_model :stylesheet,
                    name.symbolize,
                    stylesheet_params(
                        attributes.reverse_merge(:name => name) )
    end


    def stylesheet_params(attributes={})
      name = attributes[:name] || unique_stylesheet_name
      {
        :name => name,
        :content => "stylesheet content for #{name}"
      }.merge(attributes)
    end

    # Generic dataset lookup methods so we can write one spec example that handles both javascripts and
    # stylesheets.  JavascriptsDataset defines these differently.  Don't load both datasets at once.
    def text_assets(symbolic_name)
      stylesheets(symbolic_name)
    end


    def text_asset_id(symbolic_name)
      stylesheet_id(symbolic_name)
    end


    private

      @@unique_stylesheet_name_call_count = 0

      def unique_stylesheet_name
        @@unique_stylesheet_name_call_count += 1
        "stylesheet-#{@@unique_stylesheet_name_call_count}.css"
      end

  end

end

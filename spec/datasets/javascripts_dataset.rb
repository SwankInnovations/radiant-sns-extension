class JavascriptsDataset < Dataset::Base

  def load
    create_javascript "main", :content => 'Main javascript content'
  end


  helpers do

    def create_javascript(name, attributes={})
      create_model :javascript,
                    name.symbolize,
                    javascript_params(
                        attributes.reverse_merge(:name => name) )
    end


    def javascript_params(attributes={})
      name = attributes[:name] || unique_javascript_name
      {
        :name => name,
        :content => "javascript content for #{name}"
      }.merge(attributes)
    end


    # Generic dataset lookup methods so we can write one spec example that handles both javascripts and
    # stylesheets.  StylesheetsDataset defines these differently.  Don't load both datasets at once.
    def text_assets(symbolic_name)
      javascripts(symbolic_name)
    end


    def text_asset_id(symbolic_name)
      javascript_id(symbolic_name)
    end


    private

      @@unique_javascript_name_call_count = 0

      def unique_javascript_name
        @@unique_javascript_name_call_count += 1
        "javascript-#{@@unique_javascript_name_call_count}.js"
      end

  end

end
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


    # the built-in scenario helper methods only deal with the root class (i.e.
    # the one with the table -- text_asset).  So we just build our own versions.
    #
    # NOTE: There must be no symbolic naming conflics between child classes (so
    # the Stylesheets scenario and Javascripts scenario can't both have a :main
    # That's ok since we're using :main_css and :main_js naming rules here.
    def javascripts(symbolic_name)
      text_assets(symbolic_name)
    end


    def javascript_id(symbolic_name)
      text_asset_id(symbolic_name)
    end


    private

      @@unique_javascript_name_call_count = 0

      def unique_javascript_name
        @@unique_javascript_name_call_count += 1
        "javascript-#{@@unique_javascript_name_call_count}.js"
      end

  end

end
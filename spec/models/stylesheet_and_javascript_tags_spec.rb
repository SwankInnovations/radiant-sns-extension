# This specifies the behavior of the <r:stylesheet> and <r:javascript> tags.
# This includes their usage within a Page and within a Stylesheet or Javascript.
#
# Since much of their behavior is the same, it is written as such.  Should the
# tags ever take on different behavior, those differences should be added at the
# bottom of this spec or else in thier own, new spec.

require File.dirname(__FILE__) + '/../spec_helper'

[ { :asset_class => Stylesheet,
    :name => 'stylesheet',
    :default_mime_type => 'text/css',
    :inline_element => 'style' },

  { :asset_class => Javascript,
    :name => 'javascript',
    :default_mime_type => 'text/javascript',
    :inline_element => 'script' }

].each do |current_tag|

  describe "<r:#{current_tag[:name]}> tags in a Page context" do
    scenario :pages, :javascripts, :stylesheets

    before :each do
      create_page "text_asset_tags"
      @page = pages(:text_asset_tags)
    end


    it "should render an error if no 'name' attribute is provided" do
      @page.should render(%{<r:#{current_tag[:name]} />}).with_error(
          "`#{current_tag[:name]}' tag must contain a `name' attribute.")
    end


    it "should render an error when the 'name' attribute calls out an invalid filename" do
      @page.should render(%{<r:#{current_tag[:name]} name="bogus asset name" />}).with_error(
          "#{current_tag[:name]} not found")
    end


    it "should render the content of the #{current_tag[:name]} when the 'as' attribute is not provided" do
      @page.should render(%{<r:#{current_tag[:name]} name="main" />}).as(
          "Main #{current_tag[:name]} content")
    end


    it "should render the content of the #{current_tag[:name]} when the 'as' attribute is set to 'content'" do
      @page.should render(%{<r:#{current_tag[:name]} name="main" as="content" />}).as(
          "Main #{current_tag[:name]} content")
    end


    it "should render the url of the #{current_tag[:name]} when the 'as' attribute is set to 'url'" do
      StylesNScripts::Config["#{current_tag[:name]}_directory"] = 'foo/bar/baz'
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="main" as="url" />}).as(
          "foo/bar/baz/main")

      StylesNScripts::Config.restore_defaults
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="main" as="url" />}).as(
          "#{StylesNScripts::Config["#{current_tag[:name]}_directory"]}/main")
    end  




    describe "when the 'as' attribute is set to 'inline'" do

      it "should render a <#{current_tag[:inline_element]}> element containing the content of the #{current_tag[:name]} with the type attribute matching the #{current_tag[:name]}_mime_type setting" do
        # try with a custom mime_type value
        StylesNScripts::Config["#{current_tag[:name]}_mime_type"] = 'bologna'
        ActionController::Routing::Routes.reload!
        @page.should render(%{<r:#{current_tag[:name]} name="main" as="inline" />}).as(
            %{<#{current_tag[:inline_element]} type="bologna">\n} <<
            %{<!--\n} <<
            %{Main #{current_tag[:name]} content\n} <<
            %{-->\n} <<
            %{</#{current_tag[:inline_element]}>}
        )

        # try with the default mime_type value
        StylesNScripts::Config.restore_defaults
        ActionController::Routing::Routes.reload!
        @page.should render(%{<r:#{current_tag[:name]} name="main" as="inline" />}).as(
            %{<#{current_tag[:inline_element]} type="#{current_tag[:default_mime_type]}">\n} <<
            %{<!--\n} <<
            %{Main #{current_tag[:name]} content\n} <<
            %{-->\n} <<
            %{</#{current_tag[:inline_element]}>}
        )
      end


      it %{if a 'type' element is defined in the <r:#{current_tag[:name]}> tag, this should override the default value as the <#{current_tag[:inline_element]}> element's 'type' attribute} do
        @page.should render(%{<r:#{current_tag[:name]} name="main" as="inline" type="oscar" />}).as(
            %{<#{current_tag[:inline_element]} type="oscar">\n} <<
            %{<!--\n} <<
            %{Main #{current_tag[:name]} content\n} <<
            %{-->\n} <<
            %{</#{current_tag[:inline_element]}>}
        )
      end


      it %{should pass additional attributes into the <#{current_tag[:inline_element]}> element (and downcase each attribute name)} do
        StylesNScripts::Config.restore_defaults
        @page.should render(%{<r:#{current_tag[:name]} name="main" as="inline" another="mayer" ATTRIB="WEINER" />}).as(
            %{<#{current_tag[:inline_element]} type="#{current_tag[:default_mime_type]}" another="mayer" attrib="WEINER">\n} <<
            %{<!--\n} <<
            %{Main #{current_tag[:name]} content\n} <<
            %{-->\n} <<
            %{</#{current_tag[:inline_element]}>}
        )
      end      

    end

  end





  describe "<r:#{current_tag[:name]}> tags in a #{current_tag[:asset_class].to_s} context" do
    scenario :pages, :javascripts, :stylesheets

    before :each do
      @text_asset = current_tag[:asset_class].new
    end


    it "should render an error if no 'name' attribute is provided" do
      @text_asset.content = %{<r:#{current_tag[:name]} />}
      lambda{@text_asset.render}.should raise_error(
          current_tag[:asset_class]::TagError,
          "`#{current_tag[:name]}' tag must contain a `name' attribute."
      )
    end


    it "should render an error when the 'name' attribute calls out an invalid filename" do
      @text_asset.content = %{<r:#{current_tag[:name]} name="bogus asset name" />}
      lambda{@text_asset.render}.should raise_error(
          current_tag[:asset_class]::TagError,
          "#{current_tag[:name]} not found"
      )
    end


    it "should render the referenced file's content for each tag with a valid 'name' attribute" do
      send("create_#{current_tag[:name]}", "another_file")

      @text_asset.content = %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.content << %{<r:#{current_tag[:name]} name="another_file" />}
      @text_asset.content << %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.render.should == "Main #{current_tag[:name]} content" <<
                                   "#{current_tag[:name]} content for another_file" <<
                                   "Main #{current_tag[:name]} content"
    end

  end




  alternate_tag = case current_tag[:name]
    when "stylesheet"
      "javascript"
    when "javascript"
      "stylesheet"
  end

  describe "<r:#{alternate_tag}> tags in a #{current_tag[:asset_class].to_s} context" do
    it "should not be available (should throw a tag-not-found error)" do
      @text_asset = current_tag[:asset_class].new(:content => "<r:#{alternate_tag} />")
      lambda{@text_asset.render}.should raise_error(
          StandardTags::TagError,
          "undefined tag `#{alternate_tag}'"
      )
    end
  end

end
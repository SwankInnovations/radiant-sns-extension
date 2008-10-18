require File.dirname(__FILE__) + '/../spec_helper'

[ {:name => 'stylesheet',
   :main_scenario => 'main.css',
   :default_mime_type => 'text/css',
   :inline_element => 'style' },

  {:name => 'javascript',
   :main_scenario => 'main.js',
   :default_mime_type => 'text/javascript',
   :inline_element => 'script' }
].each do |current_tag|
  describe Page, "with <r:#{current_tag[:name]}> tags" do
    scenario :pages, :javascripts, :stylesheets
  
    before :each do
      create_page "text_asset_tags"
      @page = pages(:text_asset_tags)
    end
  
  
    it 'should render an error if no filename provided' do
      @page.should render(%{<r:#{current_tag[:name]} />}).with_error("`#{current_tag[:name]}' tag must contain a `name' attribute.")
    end
  
  
    it 'should render an error with an invalid filename provided' do
      @page.should render(%{<r:#{current_tag[:name]} name="bogus asset name" />}).with_error("#{current_tag[:name]} not found")
    end
  
  
    it "should render the content of the #{current_tag[:name]} when the 'as' attribute is not provided" do
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" />}).as("Main #{current_tag[:name]} content")
    end
  
  
    it "should render the content of the #{current_tag[:name]} when the 'as' attribute is set to 'content'" do
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="content" />}).as("Main #{current_tag[:name]} content")
    end
  
  
    it "should render the url of the #{current_tag[:name]} when the 'as' attribute is set to 'url'" do
      StylesNScripts::Config["#{current_tag[:name]}_directory"] = 'foo/bar/baz'
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="url" />}).as("foo/bar/baz/#{current_tag[:main_scenario]}")
  
      StylesNScripts::Config.restore_defaults
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="url" />}).as("#{StylesNScripts::Config["#{current_tag[:name]}_directory"]}/#{current_tag[:main_scenario]}")
    end  
  
  
    it "should render a <#{current_tag[:inline_element]}> element containing the content of the #{current_tag[:name]} and with the type attribute matching the #{current_tag[:name]}_mime_type setting when the 'as' attribute is set to 'inline'" do
      StylesNScripts::Config["#{current_tag[:name]}_mime_type"] = 'bologna'
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="inline" />}).as(
%{<#{current_tag[:inline_element]} type="bologna">
<!--
Main #{current_tag[:name]} content
-->
</#{current_tag[:inline_element]}>}
      )

      StylesNScripts::Config.restore_defaults
      ActionController::Routing::Routes.reload!
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="inline" />}).as(
%{<#{current_tag[:inline_element]} type="#{current_tag[:default_mime_type]}">
<!--
Main #{current_tag[:name]} content
-->
</#{current_tag[:inline_element]}>}
      )
  
    end
  
  
    it %{should override the default <#{current_tag[:inline_element]}> element's 'type' attribute if one is defined in the <r:#{current_tag[:name]}> tag} do
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="inline" type="oscar" />}).as(
%{<#{current_tag[:inline_element]} type="oscar">
<!--
Main #{current_tag[:name]} content
-->
</#{current_tag[:inline_element]}>}
      )
    end
  
  
    it %{should pass additional attributes into the <#{current_tag[:inline_element]}> element (and downcase the attribute name)} do
      @page.should render(%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" as="inline" another="mayer" ATTRIB="WEINER" />}).as(
%{<#{current_tag[:inline_element]} type="#{current_tag[:default_mime_type]}" another="mayer" attrib="WEINER">
<!--
Main #{current_tag[:name]} content
-->
</#{current_tag[:inline_element]}>}
      )
    end
  
  end
end
require File.dirname(__FILE__) + '/../spec_helper'

[ { :asset_class => Stylesheet,
    :name => 'stylesheet',
    :main_scenario => 'main.css' },

  { :asset_class => Javascript,
    :name => 'javascript',
    :main_scenario => 'main.js' }
].each do |current_tag|
  describe current_tag[:asset_class], "with <r:#{current_tag[:name]}> tags" do
    scenario :pages, :javascripts, :stylesheets

    before :each do
#      @text_asset = create_stylesheet "text_asset_tags" if current_tag[:name] == 'stylesheet'
#      @text_asset = create_javascript "text_asset_tags" if current_tag[:name] == 'javascript'
      @text_asset = current_tag[:asset_class].new
    end


    it 'should render an error if no filename provided' do
      @text_asset.content = %{<r:#{current_tag[:name]} />}
      lambda{@text_asset.render}.should raise_error(
          current_tag[:asset_class]::TagError,
          "`#{current_tag[:name]}' tag must contain a `name' attribute."
      )
    end
  
  
    it 'should render an error with an invalid filename provided' do
      @text_asset.content = %{<r:#{current_tag[:name]} name="bogus asset name" />}
      lambda{@text_asset.render}.should raise_error(
          current_tag[:asset_class]::TagError,
          "#{current_tag[:name]} not found"
      )
    end
  
  
    it "should render the content of the #{current_tag[:name]} when a valid filename is provided" do
      @text_asset.content =%{<r:#{current_tag[:name]} name="#{current_tag[:main_scenario]}" />}
      @text_asset.render.should == "Main #{current_tag[:name]} content"
    end
  
  end
end
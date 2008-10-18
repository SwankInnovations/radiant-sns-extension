require File.dirname(__FILE__) + '/../spec_helper'

describe TextAssetSiteController, "routes text_asset requests" do
  # Pages scenario is used for two reasons. First, we test for conditions where
  # pages have been created that conflict with css_ or js_directory
  # values. Secondly, at least one page must exist when SiteController goes
  # to find an uncached page or else it redirects the user to the login screen.
  scenario :javascripts, :stylesheets, :pages

  before(:each) do
    # make sure the css_ and js_directories are the default ones
    StylesNScripts::Config.restore_defaults
    ActionController::Routing::Routes.reload!

    # don't bork results with stale cache items
    controller.text_asset_cache.clear
  end

  it "should be a SiteController" do
    controller.should be_kind_of(SiteController)
  end

  it "should offer a #text_asset_cache method to access TextAssetResponseCache" do
    controller.text_asset_cache.should be_kind_of(TextAssetResponseCache)
  end

  [ { :name => 'css',
      :asset_class => 'css_asset',
      :default_directory => 'css',
      :main_scenario => 'main.css' },

    { :name => 'js',
      :asset_class => 'js_asset',
      :default_directory => 'js',
      :main_scenario => 'main.js' }

  ].each do |current_asset|
    describe current_asset[:asset_class] do

      it "should route urls based on a simple, customized setting for :#{current_asset[:name]}_directory" do
        # change the css_ or js_direectory and recreate routes to use them
        StylesNScripts::Config["#{current_asset[:name]}_directory"] = 'foo'
        ActionController::Routing::Routes.reload!

        params_from(:get, "/foo/#{current_asset[:main_scenario]}").should == 
                    { :controller => 'text_asset_site',
                      :action => 'show_text_asset',
                      :filename => [current_asset[:main_scenario]],
                      :directory => 'foo',
                      :asset_class => current_asset[:asset_class] }
      end
  
      it "should route urls based on a multi-level, customized setting for :#{current_asset[:name]}_directory" do
        # change the css_ or js_direectory and recreate routes to use them
        StylesNScripts::Config["#{current_asset[:name]}_directory"] = 'foo/bar/baz'
        ActionController::Routing::Routes.reload!

        params_from(:get, "/foo/bar/baz/#{current_asset[:main_scenario]}").should ==
                     { :controller => 'text_asset_site',
                       :action => 'show_text_asset',
                       :filename => [current_asset[:main_scenario]],
                       :directory => 'foo/bar/baz',
                       :asset_class => current_asset[:asset_class] }
      end
  
      it "should route urls based on the default when no custom settings for :#{current_asset[:name]}_directory" do
        params_from(:get, "/#{current_asset[:default_directory]}/#{current_asset[:main_scenario]}").should ==
                     { :controller => 'text_asset_site',
                       :action => 'show_text_asset',
                       :filename => [current_asset[:main_scenario]],
                       :directory => current_asset[:default_directory],
                       :asset_class => current_asset[:asset_class] }
      end
  
      it "should find and render an existing asset" do
        get :show_text_asset,
            :filename => [current_asset[:main_scenario]],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
#  For SOME reason, the response.header does not include a 'status' key so it is
#  not possible to check for success.
#        puts response.headers.keys.sort.inspect
#        response.should be_success
        response.body.should == "Main #{current_asset[:asset_class]} content"
      end
  
      it "should find and render an existing asset on the default dev site" do
        request.host = "dev.site.com"
        get :show_text_asset,
            :filename => [current_asset[:main_scenario]],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
#  For SOME reason, the response.header does not include a 'status' key so it is
#  not possible to check for success.
#        response.should be_success
        response.body.should == "Main #{current_asset[:asset_class]} content"
      end

      it "should render a 404 page for a non-existing asset" do
        get :show_text_asset,
            :filename => ['non-existent.file'],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
        response.should render_template('site/not_found')
        response.headers["Status"].should == "404 Not Found"
      end
  
      it "should render a 404 page for #{current_asset[:name]}_directory (/#{current_asset[:default_directory]}/)" do
        get :show_text_asset,
            :filename => [],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
        response.should render_template('site/not_found')
        response.headers["Status"].should == "404 Not Found"
      end
    
      it "should render a 404 page if url includes a deeper path than :#{current_asset[:name]}_directory" do
        get :show_text_asset,
            :filename => ['bogus', 'extra', 'path', 'segments', [current_asset[:main_scenario]]],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
        response.headers["Status"].should == "404 Not Found"
        response.should render_template('site/not_found')
      end
  
  
      # This is sort of dumb.  Really, users should not go anywhere near creating
      # a page with the same name as the css directory.  If they do, here's what
      # should happen.
      it "should render a page that is competing with :#{current_asset[:name]}_directory" do
        create_page current_asset[:default_directory]
        get :show_text_asset,
            :filename => [],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
        response.should be_success
        response.body.should == "#{current_asset[:default_directory]} body."
      end
  
      # Nor should they be putting child pages inside that competing page...
      it "should render a page inside :#{current_asset[:name]}_directory (immediate child of /#{current_asset[:default_directory]}/)" do
        create_page current_asset[:default_directory] do
          create_page 'page-inside'
        end
        get :show_text_asset,
            :filename => ['page-inside'],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
# WHY DOES THIS NEXT LINE FAIL?????  AAAARRRRGGGHHH!!
        response.should be_success
        response.body.should == 'page-inside body.'
      end
  
      # Or grandchildren -- but we'll test for 'em anyway.
      it "should render a page inside :#{current_asset[:name]}_directory (grandchild of /#{current_asset[:default_directory]}/)" do
        create_page current_asset[:default_directory] do
          create_page 'page-inside' do
            create_page 'another-page'
          end
        end
  
        get :show_text_asset,
            :filename => ['page-inside', 'another-page'],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
        response.should be_success
        response.body.should == 'another-page body.'
      end
      
      # But, if there's a text_asset and page -- both with the same url, then
      # the asset wins.
      it "should render the text_asset and not the page if both have the same url" do
        create_page current_asset[:default_directory] do
          create_page 'abc.123'
        end

        send("create_#{current_asset[:asset_class]}", 'abc.123')
      
        get :show_text_asset,
            :filename => ['abc.123'],
            :directory => current_asset[:default_directory],
            :asset_class => current_asset[:asset_class]
#        response.should be_success
        response.body.should == 'dummy content'
      end


    end
  end
end

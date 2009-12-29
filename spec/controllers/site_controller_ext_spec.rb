# This specifies the extended behavior of the SiteController which includes
# serving up the stylesheets and javascripts to the public.

require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController, "(Extended)" do

  integrate_views

  # Pages scenario is used for two reasons. First, we test for conditions where
  # pages urls may conflict with stylesheet_ or javascript_directory urls.
  # Secondly, at least one page must exist when SiteController goes to find an
  # uncached page or else it redirects the user to the login screen.
  dataset :javascripts, :stylesheets, :pages

  before(:each) do
    # make sure the css_ and js_directories are the default ones
    Sns::Config.restore_defaults

    # don't bork results with stale cache items
    # controller.text_asset_cache.clear
  end


  it "should be a SiteController" do
    controller.should be_kind_of(SiteController)
  end


  # it "should offer a #text_asset_cache method to access TextAssetResponseCache" do
  #   controller.text_asset_cache.should be_kind_of(TextAssetResponseCache)
  # end




  [ { :class => Stylesheet,
      :name => 'stylesheet',
      :default_directory => "css" },

    { :class => Javascript,
      :name => 'javascript',
      :default_directory => "js" }

  ].each do |current_asset|

    describe ",when routing #{current_asset[:name].pluralize}," do

      it "should send default #{current_asset[:name]}_directory urls (setting isn't customized) to #show_page action" do
        params_from(:get, "/#{current_asset[:default_directory]}/main").should ==
                    { :controller => "site",
                      :action => "show_page",
                      :url => current_asset[:default_directory].split("/") << "main" }
      end


      it "should send customized #{current_asset[:name]}_directory urls to #show_page action" do
        Sns::Config["#{current_asset[:name]}_directory"] = "foo"
        params_from(:get, "/foo/main").should ==
                    { :controller => "site",
                      :action => "show_page",
                      :url => ["foo", "main"] }
      end


      it "should send multi-level, customized #{current_asset[:name]}_directory urls to #show_page action" do
        Sns::Config[current_asset[:name] + '_directory'] = 'foo/bar/baz'
        params_from(:get, "/foo/bar/baz/main").should ==
                    { :controller => "site",
                      :action => "show_page",
                      :url => ["foo", "bar", "baz", "main"] }
      end

    end




    describe "valid GET requests" do

      it "should render the content for existing #{current_asset[:name].pluralize}" do
        get :show_page,
            :url => current_asset[:default_directory].split("/") << "main"
        response.should be_success
        response.body.should == "Main #{current_asset[:name]} content"
      end


      it "should find and render an existing #{current_asset[:name]} on the default dev site" do
        request.host = "dev.site.com"
        get :show_page,
            :url => current_asset[:default_directory].split("/") << "main"
        response.should be_success
        response.body.should == "Main #{current_asset[:name]} content"
      end


      it "should render a 404 page for a non-existing #{current_asset[:name]}" do
        get :show_page,
            :url => current_asset[:default_directory].split("/") << "non-existent.file"
        response.should render_template('site/not_found')
        
        # Not sure why status does not get set
        # response.headers["Status"].should == "404 Not Found"
      end


      it "should render a 404 page for #{current_asset[:name]}_directory (/#{current_asset[:default_directory]}/)" do
        get :show_page,
            :url => current_asset[:default_directory].split("/")
        response.should render_template('site/not_found')

        # Not sure why status does not get set
        # response.headers["Status"].should == "404 Not Found"
      end


      it "should render a 404 page if url includes a deeper path than :#{current_asset[:name]}_directory" do
        get :show_page,
            :url => current_asset[:default_directory].split("/") << 'bogus' << 'extra' << 'path' << 'main'

        # Not sure why status does not get set
        # response.headers["Status"].should == "404 Not Found"
        response.should render_template('site/not_found')
      end




      # This is sort of dumb.  Really, users should not go anywhere near creating
      # a page with the same name as the css directory.  If they do, here's what
      # should happen.
      describe "with URLs that overlap Page namespaces" do

        it "should render a page that is competing with :#{current_asset[:name]}_directory (the directory)" do
          create_page current_asset[:default_directory]
          get :show_page,
              :url => current_asset[:default_directory].split("/")
          response.should be_success
          response.body.should == "#{current_asset[:default_directory]} body."
        end


        it "should render a page inside: #{current_asset[:name]}_directory (immediate child of /#{current_asset[:default_directory]}/)" do
          create_page current_asset[:default_directory] do
            create_page 'page-inside'
          end
          get :show_page,
              :url => current_asset[:default_directory].split("/") << 'page-inside'
          response.should be_success
          response.body.should == 'page-inside body.'
        end


        it "should render a page inside: #{current_asset[:name]}_directory (grandchild of /#{current_asset[:default_directory]}/)" do
          create_page current_asset[:default_directory] do
            create_page 'page-inside' do
              create_page 'another-page'
            end
          end
          get :show_page,
              :url => current_asset[:default_directory].split("/") << 'page-inside' << 'another-page'
          response.should be_success
          response.body.should == 'another-page body.'
        end


        it "should render the #{current_asset[:name]} and not the page if both have the same url" do
          create_page current_asset[:default_directory] do
            create_page 'abc.123'
          end
          send("create_#{current_asset[:name]}", 'abc.123')
          get :show_page,
              :url => current_asset[:default_directory].split("/") << 'abc.123'
          response.should be_success
          response.body.should == "#{current_asset[:name]} content for abc.123"
        end

      end


    end

  end

end
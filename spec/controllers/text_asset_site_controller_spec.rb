# This specifies the behavior of the TextAssetSiteController which behaves much
# like Radiant's SiteController except that it serves up the stylesheets and
# javascripts to the public.  Many of these specs confirm SiteController's
# behavior from which TextAssetSiteController inherits.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe TextAssetSiteController do

  integrate_views

  # Pages scenario is used for two reasons. First, we test for conditions where
  # pages have been created that conflict with css_ or javascript_directory
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




  [ { :class => Stylesheet,
      :name => 'stylesheet',
      :default_directory => 'css' },

    { :class => Javascript,
      :name => 'javascript',
      :default_directory => 'js' }

  ].each do |current_asset|
    describe "#{current_asset[:name]} request rendering" do

      it "should route urls based on a customized setting for: #{current_asset[:name]}_directory" do
        # change the css_ or js_direectory and recreate routes to use them
        StylesNScripts::Config[current_asset[:name] + '_directory'] = 'foo'
        ActionController::Routing::Routes.reload!

        params_from(:get, "/foo/main").should == 
                    { :controller => 'text_asset_site',
                      :action => 'show_text_asset',
                      :filename => ['main'],
                      :directory => 'foo',
                      :asset_type =>  current_asset[:name] }
      end


      it "should route urls based on a multi-level, customized setting for: #{current_asset[:name]}_directory" do
        # change the css_ or js_direectory and recreate routes to use them
        StylesNScripts::Config[current_asset[:name] + '_directory'] = 'foo/bar/baz'
        ActionController::Routing::Routes.reload!

        params_from(:get, "/foo/bar/baz/main").should ==
                     { :controller => 'text_asset_site',
                       :action => 'show_text_asset',
                       :filename => ['main'],
                       :directory => 'foo/bar/baz',
                       :asset_type =>  current_asset[:name] }
      end


      it "should route urls based on the default if #{current_asset[:name]}_directory isn't customized" do
        params_from(:get, "/#{current_asset[:default_directory]}/main").should ==
                     { :controller => 'text_asset_site',
                       :action => 'show_text_asset',
                       :filename => ['main'],
                       :directory => current_asset[:default_directory],
                       :asset_type =>  current_asset[:name] }
      end


      it "should find and render an existing asset" do
        get :show_text_asset,
            :filename => ['main'],
            :directory => current_asset[:default_directory],
            :asset_type =>  current_asset[:name]
#  For SOME reason, the response.header does not include a 'status' key so it is
#  not possible to check for success.
#        response.should be_success
        response.body.should == "Main #{current_asset[:name]} content"
      end


      it "should find and render an existing asset on the default dev site" do
        request.host = "dev.site.com"
        get :show_text_asset,
            :filename => ['main'],
            :directory => current_asset[:default_directory],
            :asset_type =>  current_asset[:name]
#  For SOME reason, the response.header does not include a 'status' key so it is
#  not possible to check for success.
#        response.should be_success
        response.body.should == "Main #{current_asset[:name]} content"
      end


      it "should render a 404 page for a non-existing asset" do
        get :show_text_asset,
            :filename => ['non-existent.file'],
            :directory => current_asset[:default_directory],
            :asset_type =>  current_asset[:name]
        response.should render_template('site/not_found')
        response.headers["Status"].should == "404 Not Found"
      end


      it "should render a 404 page for #{current_asset[:name]}_directory (/#{current_asset[:default_directory]}/)" do
        get :show_text_asset,
            :filename => [],
            :directory => current_asset[:default_directory],
            :asset_type =>  current_asset[:name]
        response.should render_template('site/not_found')
        response.headers["Status"].should == "404 Not Found"
      end


      it "should render a 404 page if url includes a deeper path than :#{current_asset[:name]}_directory" do
        get :show_text_asset,
            :filename => ['bogus', 'extra', 'path', 'segments', 'main'],
            :directory => current_asset[:default_directory],
            :asset_type =>  current_asset[:name]
        response.headers["Status"].should == "404 Not Found"
        response.should render_template('site/not_found')
      end




      # This is sort of dumb.  Really, users should not go anywhere near creating
      # a page with the same name as the css directory.  If they do, here's what
      # should happen.
      describe "where page urls conflict with text asset urls" do

        it "should render a page that is competing with :#{current_asset[:name]}_directory (the directory)" do
          create_page current_asset[:default_directory]
          get :show_text_asset,
              :filename => [],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.should be_success
          response.body.should == "#{current_asset[:default_directory]} body."
        end


        it "should render a page inside: #{current_asset[:name]}_directory (immediate child of /#{current_asset[:default_directory]}/)" do
          create_page current_asset[:default_directory] do
            create_page 'page-inside'
          end
          get :show_text_asset,
              :filename => ['page-inside'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]

          response.should be_success
          response.body.should == 'page-inside body.'
        end


        it "should render a page inside: #{current_asset[:name]}_directory (grandchild of /#{current_asset[:default_directory]}/)" do
          create_page current_asset[:default_directory] do
            create_page 'page-inside' do
              create_page 'another-page'
            end
          end
          get :show_text_asset,
              :filename => ['page-inside', 'another-page'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.should be_success
          response.body.should == 'another-page body.'
        end


        it "should render the #{current_asset[:name]} and not the page if both have the same url" do
          create_page current_asset[:default_directory] do
            create_page 'abc.123'
          end
          send("create_#{current_asset[:name]}", 'abc.123')
          get :show_text_asset,
              :filename => ['abc.123'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
#  For SOME reason, the response.header does not include a 'status' key so it is
#  not possible to check for success.
#          response.should be_success
          response.body.should == "#{current_asset[:name]} content for abc.123"
        end

      end




      describe "with regard to Last-Modified date" do

        before :each do
          @dependant = current_asset[:class].new(:filename => 'dependant')
          @dependency = current_asset[:class].new(:filename => 'dependency')
          save_asset_at(@dependant, 1990)
        end


        it "should be a string" do
          get :show_text_asset,
              :filename => ['dependant'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.headers['Last-Modified'].should be_kind_of(String)
        end


        it "should use a valid HTTP header date format" do
          get :show_text_asset,
              :filename => ['dependant'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.headers['Last-Modified'].should == "Mon, 01 Jan 1990 00:00:00 GMT"
        end


        it "should reflect the #{current_asset[:name]}'s updated_at date/time if the file has no dependencies" do
          get :show_text_asset,
              :filename => ['dependant'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.headers['Last-Modified'].should == Time.gm(1990).httpdate
        end


        it "should reflect the #{current_asset[:name]}'s updated_at date/time if its dependencies are older" do
          @dependant.content = %{<r:#{current_asset[:name]} name="dependency" />}
          save_asset_at(@dependency, 1991)
          save_asset_at(@dependant, 1992)

          get :show_text_asset,
              :filename => ['dependant'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.headers['Last-Modified'].should == Time.gm(1992).httpdate
        end


        it "should reflect the #{current_asset[:name]}'s dependency's updated_at date/time if its dependencies are newer" do
          @dependant.content = %{<r:#{current_asset[:name]} name="dependency" />}
          save_asset_at(@dependant, 1993)
          save_asset_at(@dependency, 1994)

          get :show_text_asset,
              :filename => ['dependant'],
              :directory => current_asset[:default_directory],
              :asset_type =>  current_asset[:name]
          response.headers['Last-Modified'].should == Time.gm(1994).httpdate
        end
        
      end

    end

  end

end


private

  def save_asset_at(text_asset, year)
    Time.stub!(:now).and_return(Time.gm(year))
    text_asset.save!
  end

require File.dirname(__FILE__) + '/../../spec_helper'

[ { :controller => Admin::CssController,
    :controller_path => 'admin/text_asset',
    :model => Stylesheet,
    :name => 'stylesheet',
    :symbol => :stylesheet,
    :main_scenario => :main_css },

  { :controller => Admin::JsController,
    :controller_path => 'admin/text_asset',
    :model => Javascript,
    :name => 'javascript',
    :symbol => :javascript,
    :main_scenario => :main_js }

].each do |current_asset|

  describe current_asset[:controller] do

    integrate_views

    # ok, this is weird...  I would have just loaded all three scenarios but,
    # for some *strange* reason, which ever loads 2nd -- javascripts or
    # stylesheets -- trumps the previous.  Everything works fine *except* for
    # calls to text_assets(:symbolic_name).  Don't ask me why but it assumes
    # that this method should always return a Stylesheet or Javascript (which-
    # ever is loaded last).
    scenario :users, :stylesheets if current_asset[:name] == 'stylesheet'
    scenario :users, :javascripts if current_asset[:name] == 'javascript'

    test_helper :caching
  
    before :each do
      login_as :developer
      @cache = @controller.cache = FakeResponseCache.new
    end


    it "should be an AbstractModelController" do
      controller.should be_kind_of(Admin::AbstractModelController)
    end


    it "should have a model_class of #{current_asset[:name]}" do
      controller.class.model_class.should == current_asset[:model]
    end


    [:index, :new, :edit, :remove].each do |action|
      it "should require login to access the #{action} action" do
        logout
        lambda { get action }.should require_login
      end


      it "should allow access to developers" do
        lambda { get action, :id => text_asset_id(current_asset[:main_scenario]) }.should restrict_access(:allow => [users(:developer)])
      end


      it "should allow access to admins" do
        lambda { get action, :id => text_asset_id(current_asset[:main_scenario]) }.should restrict_access(:allow => [users(:admin)])
      end


      it "should deny non-developers and non-admins" do
        lambda { get action, :id => text_asset_id(current_asset[:main_scenario]) }.should restrict_access(:deny => [users(:non_admin), users(:existing)])
      end
    end


    describe "index action" do
      before :each do
        get :index
      end


      it "should be successful" do
        response.should be_success
      end


      it "should render the index template" do
        response.should render_template("#{current_asset[:controller_path]}/index")
      end


      it "should load an array of models" do
        assigns[:text_assets].should be_kind_of(Array)
        assigns[:text_assets].all? { |i| i.kind_of?(current_asset[:model]) }.should be_true
      end
    end


    describe "new action" do
      describe "via GET" do
        before :each do
          get :new
        end


        it "should be successful" do
          response.should be_success
        end


        it "should render the edit template" do
          response.should render_template("#{current_asset[:controller_path]}/edit")
        end


        it "should load a new #{current_asset[:name]}" do
          assigns[:text_asset].should_not be_nil
          assigns[:text_asset].should be_kind_of(current_asset[:model])
          assigns[:text_asset].should be_new_record
        end
      end


      describe "via POST" do
        describe "when the #{current_asset[:name]} validates" do
          before :each do
            post :new,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params")
                 @text_asset = current_asset[:model].find_by_filename('Test')
          end


          it "should redirect to the index" do
            response.should be_redirect
            response.should redirect_to(send("#{current_asset[:name]}_index_url"))
          end


          it "should create the #{current_asset[:name]}" do
            assigns[:text_asset].should_not be_new_record
          end


          it "should add a flash notice" do
            flash[:notice].should_not be_nil
            flash[:notice].should =~ /saved/
          end
        end


        describe "when the #{current_asset[:name]} fails validation" do
          before :each do
            post :new,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                      :filename => nil)
                 @text_asset = current_asset[:model].find_by_filename('Test')
          end


          it "should render the edit template" do
            response.should render_template("#{current_asset[:controller_path]}/edit")
          end


          it "should not create the #{current_asset[:name]}" do
            assigns[:text_asset].should be_new_record
          end


          it "should add a flash error" do
            flash[:error].should_not be_nil
            flash[:error].should =~ /error/
          end
        end


        describe "when 'Save and Continue Editing' was clicked" do
          before :each do
            post :new,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                      :filename => 'Test'),
                 :continue => 'Save and Continue Editing'
                 @text_asset = current_asset[:model].find_by_filename('Test')
          end


          it "should redirect to the edit action" do
            response.should be_redirect
            response.should redirect_to(send("#{current_asset[:name]}_edit_url", :id => @text_asset))
          end
        end

      end

    end


    describe "edit action" do
      describe "via GET" do
        before :each do
          get :edit, :id => text_asset_id(current_asset[:main_scenario])
        end


        it "should be successful" do
          response.should be_success
        end


        it "should render the edit template" do
          response.should render_template("#{current_asset[:controller_path]}/edit")
        end


        it "should load the existing #{current_asset[:name]}" do
          assigns[:text_asset].should_not be_nil
          assigns[:text_asset].should be_kind_of(current_asset[:model])
          assigns[:text_asset].should == text_assets(current_asset[:main_scenario])
        end
      end


      describe "via POST" do
        describe "when the #{current_asset[:name]} validates" do
          before :each do
            post :edit,
                 :id => text_asset_id(current_asset[:main_scenario]),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params")
          end


          it "should redirect to the index" do
            response.should be_redirect
            response.should redirect_to(send("#{current_asset[:name]}_index_url"))
          end


          it "should save the #{current_asset[:name]}" do
            assigns[:text_asset].should be_valid
          end


          it "should add a flash notice" do
            flash[:notice].should_not be_nil
            flash[:notice].should =~ /saved/
          end


          it "should clear the TextAssetResponseCache" do
            @cache.should be_cleared
          end
        end


        describe "when the #{current_asset[:name]} fails validation" do
          before :each do
            post :edit,
                 :id => text_asset_id(current_asset[:main_scenario]),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                      :filename => nil)
          end


          it "should render the edit template" do
            response.should render_template("#{current_asset[:controller_path]}/edit")
          end


          it "should not save the #{current_asset[:name]}" do
            assigns[:text_asset].should_not be_valid
          end


          it "should add a flash error" do
            flash[:error].should_not be_nil
            flash[:error].should =~ /error/
          end


          it "should not clear the TextAssetResponseCache" do
            @cache.should_not be_cleared
          end
        end


        describe "when 'Save and Continue Editing' was clicked" do
          before :each do
            post :edit,
                 :id => text_asset_id(current_asset[:main_scenario]),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params"),
                 :continue => 'Save and Continue Editing'
          end


          it "should redirect to the edit action" do
            response.should be_redirect
            response.should redirect_to(send("#{current_asset[:name]}_edit_url",
                                             :id => text_asset_id(current_asset[:main_scenario])))
          end


          it "should clear the TextAssetResponseCache" do
            @cache.should be_cleared
          end

        end
      end

    end


    describe "remove action" do
      describe "via GET" do
        before :each do
          get :remove, :id => text_asset_id(current_asset[:main_scenario])
        end
  
        it "should be successful" do
          response.should be_success
        end
  
        it "should render the remove template" do
          response.should render_template("#{current_asset[:controller_path]}/remove")
        end
        
        it "should load the specified #{current_asset[:name]}" do
           assigns[:text_asset].should == text_assets(current_asset[:main_scenario])
        end
      end
      
      describe "via POST" do
        before :each do
          post :remove, :id => text_asset_id(current_asset[:main_scenario])
        end
        
        it "should destroy the #{current_asset[:name]}" do
          current_asset[:model].find_by_filename(main_scenario_filename(current_asset[:main_scenario])).should be_nil
        end
        
        it "should redirect to the index action" do
          response.should be_redirect
          response.should redirect_to(send("#{current_asset[:name]}_index_url"))
        end
        
        it "should add a flash notice" do
          flash[:notice].should_not be_nil
          flash[:notice].should =~ /deleted/
        end

        it "should clear the TextAssetResponseCache" do
          @cache.should be_cleared
        end
      end
    end

  end
end


private

  # reverse calculates the filename created by the scenario (main_js -> main.js)
  def main_scenario_filename(main_scenario_symbolic_name)
    main_scenario_symbolic_name.to_s.gsub('_', '.')
  end

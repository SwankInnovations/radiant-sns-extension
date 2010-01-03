require File.dirname(__FILE__) + '/../../spec_helper'

# These specs set the behavior of TextAssetsController (which behaves as both a
# StylesheetController and JavascriptController).
#
# Many of these specs are adaptations of the AbstractController Specs.  Should
# this exension become part of core, this spec could be greatly reduced.  But
# for now, I have decided not to assume any behavior on ActionController's part.
#
# Basicaly, if we requre that it must work a certain way, then it needs to be
# confirmed. That way, if the core team sees fit to change the behavior of
# AbstractController, we'll know our extension just broke.

[ { :class => Stylesheet,
    :name => 'stylesheet',
    :symbol => :stylesheet },

  { :class => Javascript,
    :name => 'javascript',
    :symbol => :javascript }

].each do |current_asset|

  describe "For #{current_asset[:name].pluralize}, the", Admin::TextAssetsController do

    integrate_views

    # ok, this is weird...  I would have just loaded all three scenarios but,
    # for some *strange* reason, which ever loads 2nd -- javascripts or
    # stylesheets -- trumps the previous.  Everything works fine *except* for
    # calls to text_assets(:symbolic_name).  Don't ask me why but it assumes
    # that this method should always return a Stylesheet or Javascript (which-
    # ever is loaded last).
    dataset :users, :stylesheets if current_asset[:name] == 'stylesheet'
    dataset :users, :javascripts if current_asset[:name] == 'javascript'

    before :each do
      login_as :developer
    end


    it "should be an ResourceController" do
      controller.should be_kind_of(Admin::ResourceController)
    end



    # The :upload action is an addtion to the ResourceController
    [:index, :new, :edit, :remove, :upload].each do |action|

      describe "#{action} action" do

        # Different than the ResourceController, ours initializes the model
        # class just prior to each action.  So it gets spec'ed for each action.
        it "should handle #{current_asset[:name].titlecase.pluralize}" do
          get action, :asset_type => current_asset[:name], :id => text_asset_id(:main)
          controller.class.model_class.should == current_asset[:class]
        end


        it "should require login to access" do
          logout
          lambda { get action, :asset_type => current_asset[:name], :id => text_asset_id(:main) }.
              should require_login
        end


        it "should allow access to developers" do
          lambda { get action,
                   :id => text_asset_id(:main),
                   :asset_type => current_asset[:name] }.
              should restrict_access(:allow => [users(:developer)])
        end


        it "should allow access to admins" do
          lambda { get action,
                   :id => text_asset_id(:main),
                   :asset_type => current_asset[:name]}.
              should restrict_access(:allow => [users(:admin)])
        end


        it "should deny non-developers and non-admins" do
          lambda { get action, :asset_type => current_asset[:name], :id => text_asset_id(:main) }.
              should restrict_access(:deny => [users(:non_admin),
                                               users(:existing)])
        end

      end

    end




    describe "index action" do

      before :each do
        get :index, :asset_type => current_asset[:name]
      end


      it "should be successful" do
        response.should be_success
      end


      it "should render the index template" do
        response.should render_template("admin/text_assets/index")
      end


      it "should load an array of models" do
        controller.send(:models).should be_kind_of(Array)
        controller.send(:models).all? { |i| i.kind_of?(current_asset[:class]) }.should be_true
      end

    end




    describe "new action" do
      describe "via GET" do
        before :each do
          get :new, :asset_type => current_asset[:name]
        end


        it "should be successful" do
          response.should be_success
        end


        it "should render the new template" do
          response.should render_template("admin/text_assets/new")
        end


        it "should load a new #{current_asset[:name]}" do
          controller.send(:model).should_not be_nil
          controller.send(:model).should be_kind_of(current_asset[:class])
          controller.send(:model).should be_new_record
        end
      end

    end

    describe "create action" do

      describe "via POST" do

        describe "when the #{current_asset[:name]} validates" do

          before :each do
            post :create,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params"),
                 :asset_type => current_asset[:name]
            @text_asset = current_asset[:class].find_by_name('Test')
          end


          it "should redirect to the index" do
            response.should be_redirect
            response.should redirect_to(send("admin_#{current_asset[:name]}s_url"))
          end


          it "should create the #{current_asset[:name]}" do
            controller.send(:model).should_not be_new_record
          end


          it "should add a flash notice" do
            flash[:notice].should_not be_nil
            flash[:notice].should =~ /saved/
          end

        end




        describe "when the #{current_asset[:name]} fails validation" do

          before :each do
            post :create,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                  :name => nil),
                 :asset_type => current_asset[:name]
            @text_asset = current_asset[:class].find_by_name('Test')
          end


          it "should render the edit template" do
            response.should render_template("admin/text_assets/new")
          end


          it "should not create the #{current_asset[:name]}" do
            controller.send(:model).should be_new_record
          end


          it "should add a flash error" do
            response.flash[:error].should_not be_nil
            response.flash[:error].should =~ /error/
          end

        end




        describe "when 'Save and Continue Editing' was clicked" do

          before :each do
            post :create,
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                      :name => 'Test'),
                 :continue => 'Save and Continue Editing',
                 :asset_type => current_asset[:name]
            @text_asset = current_asset[:class].find_by_name('Test')
          end


          it "should redirect to the edit action" do
            response.should be_redirect
            response.should redirect_to(send("edit_admin_#{current_asset[:name]}_url", :id => @text_asset))
          end
        end

      end

    end




    describe "edit action" do

      describe "via GET" do

        before :each do
          get :edit,
              :id => text_asset_id(:main),
              :asset_type => current_asset[:name]
        end


        it "should be successful" do
          response.should be_success
        end


        it "should render the edit template" do
          response.should render_template("admin/text_assets/edit")
        end


        it "should load the existing #{current_asset[:name]}" do
          controller.send(:model).should_not be_nil
          controller.send(:model).should be_kind_of(current_asset[:class])
          controller.send(:model).should == text_assets(:main)
        end
      end

    end

    describe "update action" do

      describe "via POST" do

        describe "when the #{current_asset[:name]} validates" do

          before :each do
            post :update,
                 :id => text_asset_id(:main),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params"),
                 :asset_type => current_asset[:name]
          end


          it "should redirect to the index" do
            response.should be_redirect
            response.should redirect_to(send("admin_#{current_asset[:name]}s_url"))
          end


          it "should save the #{current_asset[:name]}" do
            controller.send(:model).should be_valid
          end


          it "should add a flash notice" do
            flash[:notice].should_not be_nil
            flash[:notice].should =~ /saved/
          end

        end




        describe "when the #{current_asset[:name]} fails validation" do

          before :each do
            post :update,
                 :id => text_asset_id(:main),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params",
                                                      :name => nil),
                 :asset_type => current_asset[:name]
          end


          it "should render the edit template" do
            response.should render_template("admin/text_assets/edit")
          end


          it "should not save the #{current_asset[:name]}" do
            controller.send(:model).should_not be_valid
          end


          it "should add a flash error" do
            response.flash[:error].should_not be_nil
            response.flash[:error].should =~ /error/
          end

        end




        describe "when 'Save and Continue Editing' was clicked" do

          before :each do
            post :update,
                 :id => text_asset_id(:main),
                 current_asset[:symbol] => send("#{current_asset[:name]}_params"),
                 :continue => 'Save and Continue Editing',
                 :asset_type => current_asset[:name]
          end


          it "should redirect to the edit action" do
            response.should be_redirect
            response.should redirect_to(send("edit_admin_#{current_asset[:name]}_url",
                                             :id => text_asset_id(:main)))
          end

        end

      end

    end




    describe "remove action" do

      describe "via GET" do

        before :each do
          get :remove,
              :id => text_asset_id(:main),
              :asset_type => current_asset[:name]
        end


        it "should be successful" do
          response.should be_success
        end


        it "should render the remove template" do
          response.should render_template("admin/text_assets/remove")
        end


        it "should load the specified #{current_asset[:name]}" do
           controller.send(:model).should == text_assets(:main)
        end

      end

    end

  end

end

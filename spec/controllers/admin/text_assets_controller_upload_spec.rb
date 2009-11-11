require File.dirname(__FILE__) + '/../../spec_helper'

# These specs define the upload behavior of TextAssetsController (which behaves
# as both a StylesheetController and JavascriptController).
#
# Since these behaviors are a departure from AbstractController and also involve
# Javascript interaction with the views, they have been separated here into
# their own spec.

[ { :class => Stylesheet,
    :name => 'stylesheet',
    :symbol => :stylesheet },

  { :class => Javascript,
    :name => 'javascript',
    :symbol => :javascript }

].each do |current_asset|

  describe "For #{current_asset[:name].pluralize}, the", Admin::TextAssetsController do

    integrate_views
    dataset :users


    before :each do
      login_as :developer
      #@cache = @controller.cache = FakeResponseCache.new
    end


    describe "upload action" do
#
#      it "should require login to access" do
#        logout
#        lambda { get :upload, :asset_type => current_asset[:name] }.
#            should require_login
#      end
#
#
#      it "should allow access to developers" do
#        lambda { get :upload,
#                     :id => text_asset_id('main'),
#                     :asset_type => current_asset[:name] }.
#            should restrict_access(:allow => [users(:developer)])
#      end
#
#
#      it "should allow access to admins" do
#        lambda { get :upload,
#                     :id => text_asset_id('main'),
#                     :asset_type => current_asset[:name]}.
#            should restrict_access(:allow => [users(:admin)])
#      end
#
#
#      it "should deny non-developers and non-admins" do
#        lambda { get :upload,
#                     :asset_type => current_asset[:name] }.
#            should restrict_access(:deny => [users(:non_admin),
#                                             users(:existing)])
#      end




      describe "via GET" do

        before :each do
          get :upload,
              :asset_type => current_asset[:name]
        end

        it "should return a 'Method Not Allowed (405)' error" do
          response.response_code.should == 405
        end


        it "should render the standard Radiant file-not-found page" do
          response.should render_template("site/not_found")
        end

      end




      describe "via POST" do

        describe "with no file in the params" do

          before :each do
            post :upload,
                 :asset_type => current_asset[:name]
          end


          it "should return a 'Bad Request (400) Error'" do
            response.response_code.should == 400
          end


          it "should return an empty body (header only)" do
            response.body.strip.should ==''
          end

        end




        describe "with a file param value that isn't a file" do

          before :each do
            post :upload,
                 :asset_type => current_asset[:name],
                 :upload => {:file => "just a string (not a real file)"}
          end


          it "should send Javascript to the parent window" do
            assert_select_parent { |script| assert_select_rjs }
          end


          it "should call showErrorsPopup() in the parent window" do
            assert_select_parent { |script|
              script.should match(%r{showErrorsPopup()})
            }
          end


          it "should replace the contents of the errors_for_#{current_asset[:name]} <div> with an 'unusable format' error message" do
            assert_select_parent { |script|
              assert_select_rjs :replace_html, "errors_for_#{current_asset[:name]}"
              assert_select_rjs do |elements|
                assert_select "ul>li", "Uploaded File: unusable format"
              end
            }
          end

        end




        describe "with a blank file param value" do

          before :each do
            post :upload,
                 :asset_type => current_asset[:name],
                 :upload => {:file => ""}
          end


          it "should send Javascript to the parent window" do
            assert_select_parent
          end


          it "should call showErrorsPopup() in the parent window" do
            assert_select_parent { |script|
              script.should match(%r{showErrorsPopup()})
            }
          end


          it "should replace the contents of the errors_for_#{current_asset[:name]} <div> with an 'no file submitted for upload' error message" do
            assert_select_parent { |script|
              assert_select_rjs :replace_html, "errors_for_#{current_asset[:name]}"
              assert_select_rjs do |elements|
                assert_select "ul>li", "Uploaded File: no file submitted for upload"
              end
            }
          end

        end




        describe "with a file that's larger than 256kB" do

          before :each do
            post :upload,
                 :asset_type => current_asset[:name],
                 :upload => {:file => mock_uploader("Paul's epistles.txt")}
          end


          it "should send Javascript to the parent window" do
            assert_select_parent
          end


          it "should call showErrorsPopup() in the parent window" do
            assert_select_parent { |script|
              script.should match(%r{showErrorsPopup()})
            }
          end


          it "should replace the contents of the errors_for_#{current_asset[:name]} <div> with an 'file size larger than 256kB' error message" do
            assert_select_parent { |script|
              assert_select_rjs :replace_html, "errors_for_#{current_asset[:name]}"
              assert_select_rjs do |elements|
                assert_select "ul>li", "Uploaded File: file size larger than 256kB"
              end
            }
          end

        end




        describe "with valid uploaded file(s)" do

          before :each do
            post :upload,
                 :asset_type => current_asset[:name],
                 :upload => {:file => mock_uploader('hello world.txt')}
          end


          it "should respond as a success" do
           response.should be_success
          end

#          # is this really a requirement to work cross browser??
#          # (the responds_to_parent plugin seems to force text/html)
#          it "should respond with a javascript content-type" do
#            mime = Mime::EXTENSION_LOOKUP['js'].to_s
#            response.headers['type'].should include(mime)
#          end


          it "should send Javascript to the parent window" do
            assert_select_parent
          end


          it "should redirect the parent window to the index page" do
            url = send("admin_#{current_asset[:name]}s_url", :only_path => true)
            js_regexp = %r{window.location.href = ['"][^'"]*#{url}['"][;]}
            assert_select_parent { |script|
              script.should match(js_regexp)
            }
          end


          it "should create a new #{current_asset[:name]} based on the uploaded file" do
            # name should be hypenated (where appropriate)
            current_asset[:class].find_by_name('hello-world.txt').content.
                should eql("Hello World! (text file)")
          end

        end

      end

    end

  end

end


private

  def mock_uploader(file, type = 'text/plain', file_class = ActionController::UploadedStringIO)
    name = "%s/%s" % [ File.dirname(__FILE__) + '/../../fixtures', file ]
    uploader = file_class.new
    uploader.original_path = name
    uploader.content_type = type

    def uploader.read
      File.read(original_path)
    end

    def uploader.size
      File.stat(original_path).size
    end

    uploader
  end
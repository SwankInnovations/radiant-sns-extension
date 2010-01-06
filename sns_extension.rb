require_dependency 'application_controller'
require 'ostruct'


class SnsExtension < Radiant::Extension
  version "0.8.2"
  extension_name "Styles 'n Scripts"
  description "Adds CSS and JS file management to Radiant"
  url "http://github.com/radiant/radiant-sns-extension"


  define_routes do |map|
    map.namespace :admin,
                  :controller => 'text_assets',
                  :member => { :remove => :get },
                  :collection => { :upload => :post } do |admin|
      
      admin.resources :stylesheets, :as => 'css', :requirements => { :asset_type => 'stylesheet'}
      admin.resources :javascripts, :as => 'js', :requirements => { :asset_type => 'javascript' }
    end
  end


  def activate
    admin.tabs.add "CSS", "/admin/css", :after => "Layouts", :visibility => [:admin, :developer]
    admin.tabs.add "JS", "/admin/js", :after => "CSS", :visibility => [:admin, :developer]

    # Include my mixins (extending PageTags and SiteController)
    Page.send :include, Sns::PageTags
    SiteController.send :include, Sns::SiteControllerExt

    Radiant::AdminUI.class_eval do
      attr_accessor :text_assets
    end
    admin.text_assets = load_default_text_assets_regions

    # Add Javascript and Stylesheet to UserActionObserver (used for created_by and updated_by)
    observables = UserActionObserver.instance.observed_classes | [Stylesheet, Javascript]
    UserActionObserver.send :observe, observables
    UserActionObserver.instance.send :add_observer!, Stylesheet
    UserActionObserver.instance.send :add_observer!, Javascript
  end


  def deactivate
    admin.tabs.remove "CSS"
    admin.tabs.remove "JS"
  end


  private

    # Defines this extension's default regions (so that we can incorporate shards
    # into its views).
    def load_default_text_assets_regions
      returning OpenStruct.new do |text_asset|
        text_asset.index = Radiant::AdminUI::RegionSet.new do |index|
          index.top.concat %w{help_text}
        end
        text_asset.edit = Radiant::AdminUI::RegionSet.new do |edit|
          edit.main.concat %w{edit_header edit_form}
          edit.form.concat %w{edit_title edit_content edit_timestamp}
          edit.content_bottom.concat %w{edit_filter}
          edit.form_bottom.concat %w{edit_buttons}
        end
        text_asset.new = text_asset.edit
      end
    end
end
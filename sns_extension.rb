# TEXT_ASSET_CACHE_DIR stores directory where text assets will be cached
# (relative to RAILS_ROOT). The default value is: "text_asset_cache"
#
# NOTE: If you change this, don't forget to remove any previous cache folder
TEXT_ASSET_CACHE_DIR = "text_asset_cache"

require_dependency 'application'
require 'ostruct'


class SnsExtension < Radiant::Extension
  version "0.7.1"
  extension_name "Styles 'n Scripts"
  description "Adds CSS and JS file management to Radiant"
  url "http://github.com/SwankInnovations/radiant-sns-extension"


  define_routes do |map|
    # Admin stylesheet Routes
    map.with_options(:controller => 'admin/text_asset', :asset_type => 'stylesheet') do |controller|
      controller.stylesheet_index   'admin/css',              :action => 'index'
      controller.stylesheet_edit    'admin/css/edit/:id',     :action => 'edit'
      controller.stylesheet_new     'admin/css/new',          :action => 'new'
      controller.stylesheet_remove  'admin/css/remove/:id',   :action => 'remove'
      controller.stylesheet_upload  'admin/css/upload',       :action => 'upload'
    end

    # Admin javascript Routes
    map.with_options(:controller => 'admin/text_asset', :asset_type => 'javascript') do |controller|
      controller.javascript_index   'admin/js',               :action => 'index'
      controller.javascript_edit    'admin/js/edit/:id',      :action => 'edit'
      controller.javascript_new     'admin/js/new',           :action => 'new'
      controller.javascript_remove  'admin/js/remove/:id',    :action => 'remove'
      controller.javascript_upload  'admin/js/upload',        :action => 'upload'
    end
  end


  def activate
    begin
      FileSystem::MODELS << "Javascript" << "Stylesheet"
    rescue NameError, LoadError
    end
    admin.tabs.add "CSS", "/admin/css", :after => "Layouts", :visibility => [:admin, :developer]
    admin.tabs.add "JS", "/admin/js", :after => "CSS", :visibility => [:admin, :developer]

    # Include my mixins (extending PageTags and SiteController)
    Page.send :include, Sns::PageTags
    SiteController.send :include, Sns::SiteControllerExt

    Radiant::AdminUI.class_eval do
      attr_accessor :text_asset
    end
    admin.text_asset = load_default_text_asset_regions


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
    def load_default_text_asset_regions
      returning OpenStruct.new do |text_asset|
        text_asset.edit = Radiant::AdminUI::RegionSet.new do |edit|
          edit.main.concat %w{edit_header edit_form}
          edit.form.concat %w{edit_title edit_content edit_timestamp}
          edit.content_bottom.concat %w{edit_filter}
          edit.form_bottom.concat %w{edit_buttons}
        end
      end
    end
end
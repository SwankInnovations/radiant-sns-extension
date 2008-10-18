# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

# allows admins to customize settings for the extension:
include CustomSettings

# minifier utilities (in /lib)
require 'jsmin.rb'
require 'cssmin.rb'


class StylesNScriptsExtension < Radiant::Extension
  version "0.2"
  extension_name "Styles 'n Scripts"
  description "Adds CSS and JS file management to Radiant"


  define_routes do |map|
    # Admin stylesheet Routes
    map.with_options(:controller => 'admin/css') do |css|
      css.css_asset_index   'admin/css',              :action => 'index'
      css.css_asset_edit    'admin/css/edit/:id',     :action => 'edit'
      css.css_asset_new     'admin/css/new',          :action => 'new'
      css.css_asset_remove  'admin/css/remove/:id',   :action => 'remove'  
    end
    
    # Admin javascript Routes
    map.with_options(:controller => 'admin/js') do |js|
      js.js_asset_index   'admin/js',              :action => 'index'
      js.js_asset_edit    'admin/js/edit/:id',     :action => 'edit'
      js.js_asset_new     'admin/js/new',          :action => 'new'
      js.js_asset_remove  'admin/js/remove/:id',   :action => 'remove'  
    end

    # Public side routes (for JS and CSS directories)
    map.connect "#{StylesNScripts::Config[:css_directory]}/*filename",
                :controller => 'text_asset_site', :action => 'show_text_asset',
                :directory => StylesNScripts::Config[:css_directory],
                :asset_class => 'css_asset'
    map.connect "#{StylesNScripts::Config[:js_directory]}/*filename",
                :controller => 'text_asset_site', :action => 'show_text_asset',
                :directory => StylesNScripts::Config[:js_directory],
                :asset_class => 'js_asset'
  end

  def activate
#    SiteController.send :include, SiteControllerMods
    admin.tabs.add "CSS", "/admin/css", :after => "Layouts", :visibility => [:admin, :developer]
    admin.tabs.add "JS", "/admin/js", :after => "CSS", :visibility => [:admin, :developer]
  end

  def deactivate
    admin.tabs.remove "CSS"
    admin.tabs.remove "JS"
  end

end
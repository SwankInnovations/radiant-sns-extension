# Initializes settings for the extension. By uncommenting lines below, you may
# customize these settings.  This file gets executed once at load time so these
# values are designed to stick until you reboot Radiant.
#
# Ideally, along with some updating to Radiant, managing these settings would 
# move to their own location in the Radiant Admin UI (probably with admin-only
# permissions).

module CustomSettings
  # always start by initializing the defauls so we know what to expect...
  StylesNScripts::Config.restore_defaults
  
  # Uncomment the items below to customize the locations from which stylesheets
  # and javascripts are served.  The default values are:
  #  * /css
  #  * /js
  #
  # These default values are not the Rails-standard 'javascript' and
  # 'stylesheets' directories because Radiant is already using those.
  #
  # Currently, you may use complex paths like:
  #   'assets/text/css'

#  StylesNScripts::Config[:stylesheet_directory] = 'my/stylesheets/go/here'
#  StylesNScripts::Config[:javascript_directory] = 'all_my_scripts'



  # Uncomment the items below to customize the MIME types for stylesheets and
  # and javascripts are served.  The default values are:
  #  * text/css
  #  * text/javascript

# StylesNScripts::Config[:stylesheet_mime_type] = "text/foo"
# StylesNScripts::Config[:javascript_mime_type] = "application/bar"


  # Uncomment the item below to customize where stylesheets and javascripts are
  # cached.  (This extension caches those files in a different location than
  # where Radiant's ResponseCache caches pages.
  #
  # Our cache (the TextAssetResponseCache) will periodically blow away this
  # entire directory so make sure you don't pick some conflicting name.  For
  # instance, choosing 'public' as your cache folder would be *bad*
  #
  # The default is:
  #  * text_asset_cache

# StylesNScripts::Config[:response_cache_directory] = "my_cache_directory"
end
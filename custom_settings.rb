# Initializes settings for the extension. By uncommenting lines below, you may
# customize these settings.
#
# Ideally, along with some updating to Radiant, managing these settings would 
# move to their own location in the Radiant Admin UI (probably with admin-only
# permissions).

module CustomSettings
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
  # but be warned, we may or may not support this in the future.

#  StylesNScripts::Config[:css_directory] = 'my_awesome_styles'
#  StylesNScripts::Config[:js_directory] = 'my_nifty_scripts')


  # Uncomment the items below to customize the MIME types for stylesheets and
  # and javascripts are served.  The default values are:
  #  * text/css
  #  * text/javascript

# StylesNScripts::Config[:css_mime_type] = "It's a Stylesheet File!"
# StylesNScripts::Config[:js_mime_type] = "It's a Javascript File!"
end
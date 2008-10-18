class RenameConfigKeysAndAddFilterId < ActiveRecord::Migration

  def self.up
    # add filter_id attribute
    add_column :text_assets, :filter_id, :string, :limit => 25

    # move all the old keys config to the new names (cleaner namespace)
    [ {:old => 'stylesheet_directory', :new => 'SnS.stylesheet_directory'},
      {:old => 'javascript_directory', :new => 'SnS.javascript_directory'},
      {:old => 'stylesheet_mime_type', :new => 'SnS.stylesheet_mime_type'},
      {:old => 'javascript_mime_type', :new => 'SnS.javascript_mime_type'}
    ].each do |keys|
      self.rename_key(keys[:old],keys[:new])
    end

    # remove the cache directory setting and, if necessary notify user of issues
    if old_cache_config = Radiant::Config.find_by_key('response_cache_directory')
      if old_cache_config.value != TEXT_ASSET_CACHE_DIR
        puts "\n                          * * * *  NOTICE  * * * *"
        puts "    The Styles 'n Scripts extension has changed the way its cache directory"
        puts "    is set and the previous setting cannot be migrated.  It can now be set"
        puts "    using TEXT_ASSET_CACHE_DIR (found in: styles_n_scripts_extension.rb)."
        puts %{\n       Your previous setting was:   "#{old_cache_config.value}"}
        puts %{       The new value is currently:  "#{TEXT_ASSET_CACHE_DIR}"}
        puts "\n    If you want to use your old value again, go change TEXT_ASSET_CACHE_DIR"
        puts "\n                          * * * * * *  * * * * * *\n\n"
        Radiant::Config.delete(old_cache_config.id)
        say 'Removed old setting for "response_cache_directory"'
      end
    end

  end


  def self.down
    remove_column :text_assets, :filter_id

    [ {:old => 'SnS.stylesheet_directory', :new => 'stylesheet_directory'},
      {:old => 'SnS.javascript_directory', :new => 'javascript_directory'},
      {:old => 'SnS.stylesheet_mime_type', :new => 'stylesheet_mime_type'},
      {:old => 'SnS.javascript_mime_type', :new => 'javascript_mime_type'}
    ].each do |keys|
      rename_key(keys[:old], keys[:new])
    end

    Radiant::Config['response_cache_directory'] = TEXT_ASSET_CACHE_DIR.gsub(/^\/+/, '').gsub(/\/+$/, '')
    say 'Copied value from TEXT_ASSET_CACHE_DIR into "response_cache_directory"'

  end


  private

    def self.rename_key(old_key, new_key)
      if config = Radiant::Config.find_by_key(old_key)
        if new_config = Radiant::Config.find_by_key(new_key)
          # new and old keys exist - move the value (weird fringe case)
          new_config.update_attribute(:value, config.value)
          Radiant::Config.delete(config.id)
        else
          config.update_attribute(:key, new_key)
        end
        say %{Moved value from "#{old_key}" to "#{new_key}"}
      end
    end

end
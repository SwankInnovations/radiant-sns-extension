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
        puts "         Styles 'n Scripts no longer has a settable cache directory"
        puts "          your existing setting cannot be used and will be deleted"
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
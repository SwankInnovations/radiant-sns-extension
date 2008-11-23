namespace :radiant do
  namespace :extensions do
    namespace :sns do

      desc "Runs migrations for SnS, and copies public assets.
      Equivalent to running `rake radiant:extensions:sns:migrate`
      then `rake radiant:extensions:sns:update` consecutively."
      task :install => [:environment, :migrate, :update] do
        puts "The SnS extension has been successfully installed."
      end


      desc "Runs the migration of the SnS extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          SnsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          SnsExtension.migrator.migrate
        end
      end


      desc "Copies public assets of SnS to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[SnsExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(SnsExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end


      desc "(Re)calculates values for all TextAssetDependencies"
      task :set_dependencies => :environment do
        puts "", "== Setting/Correcting TextAssetDependency Values =============================="
        TextAsset.find(:all, :order => 'id ASC').each do |text_asset|
          puts "", "-- setting values for #{text_asset.class.to_s.downcase}: #{text_asset.name}"
          # parse/set dependency names
          text_asset.dependency.names = text_asset.send(:parse_dependency_names)
          puts '    last updated at: ' + text_asset.updated_at.to_s
          # initially set effective update time to asset's updated_at time
          effectively_updated_at = text_asset.updated_at
          if text_asset.dependency.names.empty?
            puts '    dependencies: none'
          else
            puts '    dependencies: ' + text_asset.dependency.names.join("\n" + " " * 18)
            dependencies_updated_at = TextAsset.find_by_name(text_asset.dependency.names, :order => 'updated_at DESC').updated_at
            puts '    dependencies updated: ' + dependencies_updated_at.to_s
            effectively_updated_at = dependencies_updated_at if effectively_updated_at < dependencies_updated_at
          end
          text_asset.dependency.effectively_updated_at = effectively_updated_at
          puts '    effectively updated: ' + effectively_updated_at.to_s
          text_asset.dependency.save!
        end
      end


      desc "Configure SnS options"
      task :config => :environment do
        new_settings = {}

        # Remove all ARGVs from the front that we don't care about.
        # This lets us handle differnt input like:
        #    rake radiant:extensions:sns:config [param list]
        #    rake production radiant:extensions:sns:config [param list]
        until ARGV.shift =~ /radiant:extensions:sns:config/; end

        if ARGV.first == 'restore_defaults' && ARGV.length == 1
          # restore defaults
          print %{\nRestoring Sns::Config Defaults -> }
          Sns::Config.restore_defaults
          puts "Success"

        elsif ARGV.length == 0 || ((ARGV.first == '--help' || ARGV.first == '-help') && ARGV.length == 1 )
          #show help text
          puts "Shows and/or changes SnS configuration settings."
          puts
          puts "Usage: radiant:extensions:sns:config [option] | [setting1] [setting2] ..."
          puts "  Options (instead of using settings"
          puts "    --help, -help      Shows this info"
          puts
          puts "  Settings are of the form 'setting=value' like:"
          puts "      radiant:extensions:sns:config js_dir=my_javascripts"
          puts
          puts "  Allowable settings:"
          puts "    css_dir            Sets the server's stylesheet_directory"
          puts "    js_dir             Sets the server's javascript_directory"
          puts "    css_mime           Sets the server's stylesheet_mime_type"
          puts "    js_mime            Sets the server's javascript_mime_type"
          puts "    reset_all          Restores all settings to the factory original"
          puts
          puts "The current value for TEXT_ASSET_CACHE_DIR is displayed here for your"
          puts "convenience but it cannot be changed. If you must change it, you can"
          puts "via the sns_extension.rb file. Doing so requires restarting Radiant."

        else
          # iterate through each argument and verify each is well-formed
          ARGV.each do |argument|
            arg_elements = argument.split("=")
            raise(%{Invalid parameter: "#{argument}"}) unless arg_elements.length == 2
            case arg_elements.first
              when 'css_dir', 'stylesheet_directory'
                arg_elements[0] = 'stylesheet_directory'
              when 'js_dir', 'javascript_directory'
                arg_elements[0] = 'javascript_directory'
              when 'css_mime', 'stylesheet_mime_type'
                arg_elements[0] = 'stylesheet_mime_type'
              when 'js_mime', 'javascript_mime_type'
                arg_elements[0] = 'javascript_mime_type'
              else
                raise %{Invalid setting name: "#{arg_elements[0]}"}
            end
            new_settings[arg_elements[0]] = arg_elements[1]
          end

          # now that we know the input was ok, let's set 'em
          new_settings.each do |k,v|
            print %{--setting Sns::Config[#{k}] = "#{v}" -> }
            Sns::Config[k] = v
            puts "Success"
          end
        end

        # follow up by showing the current state of settings
        puts "\n  Current Styles 'n Scripts Configuration:\n\n"
        # convert the hash into an array to sort by key name (pair[0])
        Sns::Config.to_hash.to_a.sort_by { |pair| pair[0] }.each do |pair|
          puts %{    #{pair[0].to_s.ljust(24)} "#{pair[1].to_s}"}
        end
        puts %{\n    TEXT_ASSET_CACHE_DIR     "#{TEXT_ASSET_CACHE_DIR}"}
      end

    end
  end
end
namespace :radiant do
  namespace :extensions do
    namespace :styles_n_scripts do

      desc "Runs the migration of the SnS extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          StylesNScriptsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          StylesNScriptsExtension.migrator.migrate
        end
      end


      desc "Copies public assets of SnS to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[StylesNScriptsExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(StylesNScriptsExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end


      desc "Configure SnS options"
      task :config => :environment do
        new_settings = {}

        if ARGV.length == 2 && ARGV[1] = 'restore_defaults'
          print %{\nRestoring StylesNScripts::Config Defaults -> }
          StylesNScripts::Config.restore_defaults
          puts "Success"


        else
          # iterate through each argument (except ARGV[0]) and verify well-formed
          ARGV[1..ARGV.length-1].each do |argument|
            arg_elements = argument.split("=")
            raise(%{Invalid parameter: "#{argument}"}) unless arg_elements.length == 2
            new_settings[arg_elements[0]] = arg_elements[1]
          end

          new_settings.each do |k,v|
            print %{--setting StylesNScripts::Config[#{k}] = "#{v}" -> }
            StylesNScripts::Config[k] = v
            puts "Success"
          end
        end

        puts "\n  Current Styles 'n Scripts Configuration:\n\n"
        # convert the hash into an array to sort by key name (pair[0])
        StylesNScripts::Config.to_hash.to_a.sort_by { |pair| pair[0] }.each do |pair|
          puts %{    #{pair[0].to_s.ljust(24)} "#{pair[1].to_s}"}
        end
        puts %{\n    TEXT_ASSET_CACHE_DIR     "#{TEXT_ASSET_CACHE_DIR}"}
      end

    end
  end
end
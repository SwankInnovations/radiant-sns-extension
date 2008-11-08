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


      desc "Configure SnS options"
      task :config => :environment do
        new_settings = {}

        if ARGV.length == 2 && ARGV[1] = 'restore_defaults'
          print %{\nRestoring Sns::Config Defaults -> }
          Sns::Config.restore_defaults
          puts "Success"


        else
          # iterate through each argument (except ARGV[0]) and verify well-formed
          ARGV[1..ARGV.length-1].each do |argument|
            arg_elements = argument.split("=")
            raise(%{Invalid parameter: "#{argument}"}) unless arg_elements.length == 2
            new_settings[arg_elements[0]] = arg_elements[1]
          end

          new_settings.each do |k,v|
            print %{--setting Sns::Config[#{k}] = "#{v}" -> }
            Sns::Config[k] = v
            puts "Success"
          end
        end

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
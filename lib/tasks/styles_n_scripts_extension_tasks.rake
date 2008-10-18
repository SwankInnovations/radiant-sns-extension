namespace :radiant do
  namespace :extensions do
    namespace :styles_n_scripts do
      
      desc "Runs the migration of the Styles N Scripts extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          StylesNScriptsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          StylesNScriptsExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Styles N Scripts to the instance public/ directory."
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
    end
  end
end

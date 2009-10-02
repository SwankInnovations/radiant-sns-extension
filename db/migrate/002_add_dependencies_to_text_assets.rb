class AddDependenciesToTextAssets < ActiveRecord::Migration
  def self.up
    if TextAsset.count > 0
      puts "\n                          * * * *  NOTICE  * * * *"
      puts "         This migration used to populate the newly-created dependencies"
      puts "           table but the previous models have since changed.  So, now"
      puts "                    this step only creates the empty table."
      puts "\n                        Normally, this ist a problem..."
      puts "\n        BUT we have detected existing records in your text_assets table"
      puts "         which now won't have associated text_asset_dependency records."
      puts "\n          To solve this, you will need to run the following rake task"
      puts "                  once you've fully migrated your database:"
      puts "       rake #{RAILS_ENV} radiant:extensions:sns:rebuild_dependencies"
      puts "\n                          * * * * * *  * * * * * *\n\n"
      puts "Press 'enter' to acknowledge and proceed with the migration(s):"
      STDIN.gets
    end

    create_table :text_asset_dependencies do |t|
      t.integer   :text_asset_id
      t.string    :list
      t.datetime  :effectively_updated_at
    end 
  end


  def self.down
    drop_table :text_asset_dependencies
  end
end

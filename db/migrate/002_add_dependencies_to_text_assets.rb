class AddDependenciesToTextAssets < ActiveRecord::Migration
  def self.up
    create_table :text_asset_dependencies do |t|
      t.integer   :text_asset_id
      t.string    :list
      t.datetime  :effectively_updated_at
    end

    # Calculate values for new table.  So, iterate over all TextAssets and...
    TextAsset.find(:all).sort_by{|i| i.id}.each do |text_asset|
      # Set the dependency list
      text_asset.dependencies = TextAssetDependencies.new(:list => [])
      TextAssetObserver.instance.update_dependencies(text_asset)

      # get the actual dependency objects referenced by dependencies.list
      dependencies = text_asset.class.find_all_by_filename(text_asset.dependencies.list).compact
      unless dependencies.empty?

        # find the most recently updated dependency
        dependencies_updated_at = dependencies.sort_by{|i| i.updated_at}.last.updated_at

        # figure out which is newer -> the asset or it's dependencies
        if dependencies_updated_at > text_asset.updated_at
          # Adjust the effectively_updated_at value (if different than set by updated_dependencies)
          text_asset.dependencies.effectively_updated_at = dependencies_updated_at
          text_asset.dependencies.save!
        end
      end
      say "Completed dependency calculations for #{text_asset.url}"
    end

  end


  def self.down
    drop_table :text_asset_dependencies
  end
end

class AddDependenciesToTextAssets < ActiveRecord::Migration
  def self.up
    # because this migration performs calculations, the table must be updated to
    # work with the exisiting models.
    add_column :text_assets, :name, :string
    create_table :text_asset_dependencies do |t|
      t.integer   :text_asset_id
      t.string    :names
      t.datetime  :effectively_updated_at
    end

    # Calculate values for new table.  So, iterate over all TextAssets and...
    TextAsset.find(:all).sort_by{|i| i.id}.each do |text_asset|
      say "Calculating dependencies for #{text_asset.class.downcase}: #{text_asset.filename}"
      # Set the dependency list
      text_asset.dependency = TextAssetDependency.new(:names => [])
      text_asset.dependency.update_attribute('names', text_asset.send(:parse_dependency_names))

      # get the actual dependency objects referenced by dependency.names
      dependency_names = text_asset.class.find_all_by_filename(text_asset.dependency.names).compact
      unless dependency_names.empty?

        # find the most recently updated dependency
        dependencies_updated_at = dependency_names.sort_by{|i| i.updated_at}.last.updated_at

        # figure out which is newer -> the asset or it's dependencies
        if dependencies_updated_at > text_asset.updated_at
          # Adjust the effectively_updated_at value (if different than set by updated_dependencies)
          text_asset.dependency.effectively_updated_at = dependencies_updated_at
          text_asset.dependency.save!
        end
      end
    end

    # reset the names and filename fields per this migration
    rename_column :text_asset_dependencies, :names, :list
    remove_column :text_assets, :name
  end


  def self.down
    drop_table :text_asset_dependencies
  end
end

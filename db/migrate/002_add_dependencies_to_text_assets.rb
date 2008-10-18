class AddDependenciesToTextAssets < ActiveRecord::Migration
  def self.up
    add_column :text_assets, :dependencies, :string
    # iterate through Javascripts and Stylesheets and save! each to trigger
    # update_dependencies and save the results to the new dependencies field
    TextAsset.find(:all).each do |text_asset|
      text_asset.class.record_timestamps = false
      text_asset.save!
      text_asset.class.record_timestamps = true
    end
  end

  def self.down
    remove_column :text_assets, :dependencies
  end
end

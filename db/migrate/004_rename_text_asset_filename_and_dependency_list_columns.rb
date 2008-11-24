class RenameTextAssetFilenameAndDependencyListColumns < ActiveRecord::Migration
  def self.up
    rename_column :text_assets, :filename, :name
    rename_column :text_asset_dependencies, :list, :names
  end

  def self.down
    rename_column :text_asset_dependencies, :names, :list
    rename_column :text_assets, :name, :filename
  end
end
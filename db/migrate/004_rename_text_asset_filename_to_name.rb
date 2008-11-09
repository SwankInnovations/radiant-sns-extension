class RenameTextAssetFilenameToName < ActiveRecord::Migration
  def self.up
    rename_column :text_assets, :filename, :name
  end
  
  def self.down
    rename_column :text_assets, :name, :filename
  end
end
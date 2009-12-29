class RemoveTextAssetDependenciesTable < ActiveRecord::Migration
  def self.up
    drop_table :text_asset_dependencies
  end

  def self.down
    create_table :text_asset_dependencies do |t|
      t.integer   :text_asset_id
      t.string    :names
      t.datetime  :effectively_updated_at
    end
  end
end
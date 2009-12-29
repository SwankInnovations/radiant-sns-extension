class AddDependenciesToTextAssets < ActiveRecord::Migration
  def self.up
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
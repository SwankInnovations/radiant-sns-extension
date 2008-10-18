class CreateTextAssets < ActiveRecord::Migration

  def self.up
    create_table :text_assets do |t|
      t.string  :class_name, :limit => 25
      t.string  :filename, :limit => 100
      t.text    :content
      t.timestamps
      t.integer :created_by_id, :updated_by_id, :lock_version
    end
  end


  def self.down
    drop_table :text_assets
  end

end

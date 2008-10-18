class CreateTextAssets < ActiveRecord::Migration
  def self.up
    create_table :text_assets do |t|
      t.string  :class_name, :limit => 25
      t.string  :filename, :limit => 100
      t.text    :raw_content
      t.integer :created_by, :updated_by, :lock_version
      t.boolean :minify, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :text_assets
  end
end

class AddNameClassNameIndex < ActiveRecord::Migration
  def self.up
    add_index :text_assets, [:name, :class_name]
  end

  def self.down
    remove_index :text_assets, [:name, :class_name]
  end
end

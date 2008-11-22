class TextAssetDependency < ActiveRecord::Base
  belongs_to :text_asset
  serialize :names, Array
end
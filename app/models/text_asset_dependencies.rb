class TextAssetDependencies < ActiveRecord::Base

  belongs_to :text_asset
  serialize :list, Array

end
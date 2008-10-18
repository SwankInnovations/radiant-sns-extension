class Admin::JsController < Admin::TextAssetController
  model_class JsAsset

  only_allow_access_to :index, :new, :edit, :remove,
    :when => [:developer, :admin],
    :denied_url => { :controller => 'page', :action => 'index' },
    :denied_message => 'You must have developer privileges to perform this action.'
end

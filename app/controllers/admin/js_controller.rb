class Admin::JsController < Admin::TextAssetController
  model_class Javascript

  only_allow_access_to :index, :new, :edit, :remove,
    :when => [:developer, :admin],
    :denied_url => { :controller => 'page', :action => 'index' },
    :denied_message => 'You must have developer or administrator privileges to perform this action.'
end

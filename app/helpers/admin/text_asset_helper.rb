module Admin::TextAssetHelper

  def model_name
    (@model_name || @text_asset.class).to_s.underscore
  end


  def proper_model_name
    model_name.humanize.titlecase
  end

end

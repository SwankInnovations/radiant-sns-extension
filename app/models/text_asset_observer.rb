class TextAssetObserver < ActiveRecord::Observer
  observe Stylesheet, Javascript

  def after_save(model)
    update_dependants(model, model.updated_at)
    model.dependency.save
  end


  def after_destroy(model)
    update_dependants(model, Time.now)
  end


  def update_dependants(model, time)
    model.class.find(:all).each do |text_asset|
      if text_asset.name == model.name
        # if itself, effectively_updated_at should match it's just save_at time
        model.dependency.effectively_updated_at = model.updated_at
      elsif !text_asset.dependency.names.empty?
        if text_asset.dependency.names.include?(model.name)
          text_asset.dependency.update_attribute('effectively_updated_at', time)
        end
      end
    end
  end

end
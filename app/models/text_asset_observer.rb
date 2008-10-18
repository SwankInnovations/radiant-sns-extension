class TextAssetObserver < ActiveRecord::Observer
  observe Stylesheet, Javascript
  
  def after_save(model)
    update_dependencies(model, model.updated_at)
    update_other_dependants(model, model.updated_at)
  end


  def after_destroy(model)
    update_other_dependants(model, Time.now)
  end


  def update_dependencies(model, time = nil)
    # the parse operation populates the dependencies list (clear it first)
    model.dependencies.list = []
    model.parse(model.content, false)
    model.dependencies.list.uniq!

    # set the effectively_updated_at time too
    model.dependencies.effectively_updated_at = time unless time.nil?

    model.dependencies.save!
  end


  def update_other_dependants(model, time)
    model.class.find(:all).each do |text_asset|
      unless text_asset.filename == model.filename || text_asset.dependencies.list.empty?
        if text_asset.dependencies.list.include?(model.filename)
          text_asset.dependencies.update_attribute('effectively_updated_at', time)
        end
      end
    end
  end

end
module FileSystem::Model::JavascriptExtensions
  
  include TextAsset
  
  private
    def default_content_type
      "js"
    end
end
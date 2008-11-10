module FileSystem::Model::StylesheetExtensions
  
  include TextAsset
  
  private
    def default_content_type
      "css"
    end
  
end
module FileSystem::Model::StylesheetExtensions
  
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end
  
  module ClassMethods
    def klass_name
      "Stylesheet"
    end
  end
  
  private
    def default_content_type
      "css"
    end
    
end
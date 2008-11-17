module FileSystem::Model::JavascriptExtensions
  
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end
  
  module ClassMethods
    def klass_name
      "Javascript"
    end
  end
  
  private
    def default_content_type
      "js"
    end
  
end
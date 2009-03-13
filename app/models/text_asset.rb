class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  order_by 'name'

  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_one :dependency, :class_name => 'TextAssetDependency', :dependent => :destroy

  validates_presence_of :name, :message => 'required'
  validates_length_of :name, :maximum => 100, :message => '{{count}}-character limit'
  validates_uniqueness_of :name, :scope => :class_name, :message => "name already in use"
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :name, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  object_id_attr :filter, TextAssetFilter

  include Radiant::Taggable
  class TagError < StandardError; end


  def after_initialize
    self.dependency = TextAssetDependency.new(:names => []) if self.new_record?
    # add radius tags to the inherited class now that it has initialized
    create_tags
  end


  # Ensures that the associated 'dependency' model is saved and alerts potential
  # dependants that this instance has been updated
  def after_save
    self.dependency.names = parse_dependency_names
    self.dependency.effectively_updated_at = self.updated_at
    self.dependency.save
    update_dependants(self.updated_at)
  end


  # Alert all potential dependants that this instance has been updated
  def after_destroy
    update_dependants(Time.now)
  end


  # URL relative to the web root (accounting for Sns::Config settings)
  def url
    "/" + Sns::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.name
  end


  # Convenience method
  def effectively_updated_at
    self.dependency.effectively_updated_at
  end


  # This method is called from outside to notify this instance that another
  # text asset has been updated.
  def process_newly_updated_dependency(name, time)
    if self.dependency.names.include?(name)
      self.dependency.update_attribute('effectively_updated_at', time)
    end
  end


  # Parses, and filters the current content for output
  def render
    self.filter.filter(parse(self.content))
  end


  # Parses the content using a TextAssetContext
  def parse(text, show_errors = true)
    @parsed_dependency_names = []
    unless @parser and @context
      @context = TextAssetContext.new(self)
      @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
    end
    @context.show_errors = show_errors
    @parser.parse(text)
  end


  # Takes an uploaded file (in memory) and creates a new text asset from it
  def self.create_from_file(file)
    @text_asset = self.new
    if file.blank?
      @text_asset.errors.add(:uploaded_file, 'no file submitted for upload')

    elsif !file.kind_of?(ActionController::UploadedFile)
      @text_asset.errors.add(:uploaded_file, 'unusable format')

    elsif file.size > 262144 # 256k (that's a HUGE script or stylesheet)
      @text_asset.errors.add(:uploaded_file, 'file size larger than 256kB')

    else
      @text_asset.name = file.original_filename.gsub(/\s/, '-')
      @text_asset.content = file.read
      # everthing else passed so run through the std validations (save if valid)
      @text_asset.save
    end
    @text_asset
  end


  private

    # Parses the content and builds an array of all refrenced text_assets (from
    # within tags).
    def parse_dependency_names
      parse(self.content, false)
      @parsed_dependency_names.uniq
    end


    # Finds all text_assets of the same class and alerts each that this instance
    # has just been updated
    def update_dependants(time)
      self.class.find(:all).each do |other_text_asset|
        unless other_text_asset.name == self.name
          other_text_asset.process_newly_updated_dependency(self.name, time)
        end
      end
    end


    # Adds a tag named after the inheriting class name (i.e. <r:javascript> or
    # <r:stylesheet>).  This method is kind of funky since we wanted to define
    # the tag in only one place yet we don't have the inheriting class' name
    # until after initialization.
    def create_tags
      self.class.class_eval do
        tag(self.name.underscore) do |tag|
          if name = tag.attr['name']
            @parsed_dependency_names << name.strip
            if text_asset = self.class.find_by_name(name.strip)
              text_asset.render
            else
              raise TagError.new("#{self.class.to_s.underscore} with name '#{name}' not found")
            end
          else
            raise TagError.new("`#{self.class.to_s.underscore}' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
          end
        end
      end
    end

end
class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  order_by 'name'

  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_one :dependency, :class_name => 'TextAssetDependency', :dependent => :destroy

  validates_presence_of :name, :message => 'required'
  validates_length_of :name, :maximum => 100, :message => '%d-character limit'
  validates_uniqueness_of :name, :scope => :class_name, :message => "name already in use"
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :name, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  before_save :parse_dependency_names
  
  object_id_attr :filter, TextAssetFilter

  include Radiant::Taggable
  class TagError < StandardError; end


  def after_initialize
    self.dependency = TextAssetDependency.new(:names => []) if new_record?
    create_tags #adds radius tags to the inherited class now that it has initialized
  end


  def url
    "/" + Sns::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.name
  end


  def effectively_updated_at
    if dependency.effectively_updated_at.nil?
      dependency_names = self.dependency.names || parse_dependency_names
      self.dependency.effectively_updated_at = TextAsset.find_by_name(names, :order => "updated_at DESC").updated_at
      self.dependency.save
    end
    self.dependency.effectively_updated_at
  end

  
  def parse_dependency_names
    parse(self.content, false)
    self.dependency.names = @parsed_dependency_names.uniq
  end


  def render
    text = self.content
    text = parse(text)
    text = self.filter.filter(text)
    text
  end


  def parse(text, show_errors = true)
    @parsed_dependency_names = []
    unless @parser and @context
      @context = TextAssetContext.new(self)
      @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
    end
    @context.show_errors = show_errors
    @parser.parse(text)
  end


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

    # Adds a tag named after the inheriting class name (i.e. <r:javascript> or
    # <r:stylesheet>).  This method is kind of funky since we wanted to define
    # the tag in only one place yet we don't have the inheriting class' name
    # until after initialization.
    def create_tags
      self.class.class_eval do
        tag(self.name.underscore) do |tag|
          if name = tag.attr['name']
            @parsed_dependency_names << tag.attr['name'].strip
            if text_asset = self.class.find_by_name(tag.attr['name'].strip)
              text_asset.render
            else
              raise TagError.new("#{self.class.to_s.underscore} not found")
            end
          else
            raise TagError.new("`#{self.class.to_s.underscore}' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
          end
        end
      end
    end

end
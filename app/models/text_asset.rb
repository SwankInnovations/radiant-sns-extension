class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  default_scope :order => "name ASC"

  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'

  validates_presence_of :name, :message => 'required'
  validates_length_of :name, :maximum => 100, :message => '{{count}}-character limit'
  validates_uniqueness_of :name, :scope => :class_name, :message => "name already in use"
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :name, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  object_id_attr :filter, TextAssetFilter


  include Radiant::Taggable
  class TagError < StandardError; end


  # URL relative to the web root (accounting for Sns::Config settings)
  def url
    "/" + Sns::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.name
  end


  # Parses, and filters the current content for output
  def render
    self.filter.filter(parse(self.content))
  end


  # Parses the content using a TextAssetContext
  def parse(text)
    unless @parser and @context
      @context = TextAssetContext.new(self)
      @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
    end
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

end
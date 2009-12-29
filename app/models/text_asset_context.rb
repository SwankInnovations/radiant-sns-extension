class TextAssetContext < Radius::Context

  def initialize(text_asset)
    super()
    globals.text_asset = text_asset
    text_asset.tags.each do |name|
      define_tag(name) { |tag_binding| text_asset.render_tag(name, tag_binding) }
    end
  end


  def render_tag(name, attributes = {}, &block)
    super
  rescue Exception => e
    raise e if raise_errors?
    @tag_binding_stack.pop unless @tag_binding_stack.last == binding
    e.message
  end


  def tag_missing(name, attributes = {}, &block)
    super
  rescue Radius::UndefinedTagError => e
    raise StandardTags::TagError.new(e.message)
  end


  private

    def raise_errors?
      RAILS_ENV != 'production'
    end

end

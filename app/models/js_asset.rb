class JsAsset < TextAsset

  def content
    if self.minify?
      JSMin.minify(self.raw_content)
    else
      super
    end
  end

end

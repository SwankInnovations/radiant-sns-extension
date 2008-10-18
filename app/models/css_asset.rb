class CssAsset < TextAsset

  def content
    if self.minify?
      CSSMin.minify(self.raw_content)
    else
      super
    end
  end

end

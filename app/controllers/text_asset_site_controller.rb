class TextAssetSiteController < SiteController
# This controller adds functionality to site controller to render text_assets
# (similarly to how it renders pages).  This interacts with my
# TextAssetResponseCache model (which behaves very much like ResponseCache)
# to cache file items in their own separate cache.

  def text_asset_cache
    @text_asset_cache ||= TextAssetResponseCache.instance
  end


  def show_text_asset
    response.headers.delete('Cache-Control')

    filename = params[:filename].join('/')
    url = "#{params[:directory]}/#{filename}"

    if (request.get? || request.head?) and live? and (text_asset_cache.response_cached?(url))
      @text_asset_cache.update_response(url, response, request)
      @performed_render = true
    else
      show_uncached_text_asset(filename, params[:asset_class], url)
    end
  end


  private

    def show_uncached_text_asset(filename, asset_class, url)
      case asset_class
        when 'stylesheet'
          @text_asset = Stylesheet.find_by_filename(filename)      
          mime_type = StylesNScripts::Config[:stylesheet_mime_type]
        when 'javascript'
          @text_asset = Javascript.find_by_filename(filename)
          mime_type = StylesNScripts::Config[:javascript_mime_type]
      end
      unless @text_asset.nil?
        response.headers['Content-Type'] = mime_type
        # set the last modified date based on updated_at time for the asset
        # we can do this as long as there is no dynamic content in the assets
        response.headers['Last-Modified'] = @text_asset.updated_at
        response.body = @text_asset.content

        # for text_assets, we cache no matter what (there's no status setting for them)
        text_asset_cache.cache_response(url, response) if request.get?
        @performed_render = true
      else
        params[:url] = url
        show_page
      end
    end

end
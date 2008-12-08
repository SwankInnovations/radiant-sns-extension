module Sns
  module SiteControllerExt

    def self.included(base)
      base.class_eval do
        skip_before_filter :authenticate
        before_filter :parse_url_for_text_assets, :only => :show_page
      end
    end

    def text_asset_cache
      @text_asset_cache ||= TextAssetResponseCache.instance
    end


    private

      def parse_url_for_text_assets
        url = params[:url]
        if url.kind_of?(Array)
          url = url.join('/')
        else
          url = url.to_s
        end
        if url =~ %r{^\/?(#{Sns::Config[:stylesheet_directory]})\/(.*)$}
          show_text_asset($2, 'stylesheet')

        elsif url =~ %r{^\/?(#{Sns::Config[:javascript_directory]})\/(.*)$}
          show_text_asset($2, 'javascript')
        end
      end

      def show_text_asset(name, asset_type)
        response.headers.delete('Cache-Control')
        cache_url = "#{asset_type}_cache/#{name}"

        if (request.get? || request.head?) and live? and (text_asset_cache.response_cached?(cache_url))
          text_asset_cache.update_response(cache_url, response, request)
          @performed_render = true
        else
          show_uncached_text_asset(name, asset_type, cache_url)
        end
      end

      def show_uncached_text_asset(name, asset_type, cache_url)
        @text_asset = asset_type.camelcase.constantize.find_by_name(name)
        mime_type = Sns::Config["#{asset_type}_mime_type"]

        unless @text_asset.nil?
          response.body = @text_asset.render
          response.headers['Status'] = ActionController::Base::DEFAULT_RENDER_STATUS_CODE
          response.headers['Content-Type'] = mime_type
          response.headers['Last-Modified'] = @text_asset.effectively_updated_at.httpdate
          text_asset_cache.cache_response(cache_url, response) if request.get?
          @performed_render = true
        end
      end

  end
end
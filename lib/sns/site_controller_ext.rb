module Sns
  module SiteControllerExt

    def self.included(base)
      base.class_eval do
        skip_before_filter :authenticate
        before_filter :parse_url_for_text_assets, :only => :show_page
      end
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
          text_asset = Stylesheet.find_by_name($2)
          if text_asset
            set_text_asset_cache_control
            process_text_asset(text_asset, 'stylesheet')
            @performed_render = true
          end

        elsif url =~ %r{^\/?(#{Sns::Config[:javascript_directory]})\/(.*)$}
          text_asset = Javascript.find_by_name($2)
          if text_asset
            set_text_asset_cache_control
            process_text_asset(text_asset, 'javascript')
            @performed_render = true
          end
        end
      end
      
      def set_text_asset_cache_control
        expires_in Sns::Config['cache_timeout'], :public => true, :private => false
      end
      
      def process_text_asset(text_asset, asset_type)
        response.body = text_asset.render
        response.status = ActionController::Base::DEFAULT_RENDER_STATUS_CODE
        response.headers['Content-Type'] = Sns::Config["#{asset_type}_mime_type"]
      end
  end
end
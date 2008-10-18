module StylesNScripts

  class Config

    # stores the default values for the settings
    # note: key names *must* be declared as strings -- *not* as symbols
    @defaults = { 'stylesheet_directory' => 'css',
                  'javascript_directory' => 'js',
                  'stylesheet_mime_type' => 'text/css',
                  'javascript_mime_type' => 'text/javascript',
                  'response_cache_directory' => 'text_asset_cache'
                }

    @@live_config = {}


    class << self

      # Getter for the config values.  Includes a set of conditionals to
      # incrementally test whether the live_config and then the Radiant::Config
      # values are set and, if not, calls in the default values.  I would have
      # preferred to use something more like:
      #     @@live_config[key] ||= Radiant::Config[key] ||= @defaults[key])
      # but Radiant::Config recasts nil values into empty strings.
      def [](key)
        key = key.to_s
        validate_key(key)
        if @@live_config[key].blank?
          @@live_config[key] = Radiant::Config[key]
          if @@live_config[key].blank?
            @@live_config[key] = Radiant::Config[key] = @defaults[key]
          end
        end
        @@live_config[key]
      end


      # Setter for Config key/value pairs.  Keys must be limited to valid
      # settings for the extension.
      def []=(key, value)
        # key must be in the form of a string for Radiant:Config
        key = key.to_s

        case key
          when 'response_cache_directory'
            value = validate_cache_directory(value, key)
          when /_directory$/
            value = validate_directory(value, key)
          when /_mime_type$/
            validate_mime_type(value, key)
        end

        @@live_config[key] = Radiant::Config[key] = value
      end


      def restore_defaults
        @defaults.each do |key, value|
          Radiant::Config[key] = value
        end
        @@live_config = {}
      end


      private

        # determines whether 'key' matches one of the keys in @defaults (
        def validate_key(key)
          raise("invalid setting name: #{key.inspect}") unless @defaults.has_key?(key)
        end


        def validate_cache_directory(directory, directory_label)
          raise("invalid #{directory_label} value: #{directory.inspect}") unless directory =~ %r{\A/?[-_A-Za-z0-9]*/?\Z}
          # return value with leading/trailing slashes removed
          directory.gsub(/^\//, '').gsub(/\/$/, '')
        end


        def validate_directory(directory, directory_label)
          raise("invalid #{directory_label} value: #{directory.inspect}") unless directory =~ %r{\A/?[-_A-Za-z0-9]+(/[-_A-Za-z0-9]+)*/?\Z}
          # return value with leading/trailing slashes removed
          directory.gsub(/^\//, '').gsub(/\/$/, '')
        end


        def validate_mime_type(mime_type, mime_type_label)
          raise("invalid #{mime_type_label} value: #{mime_type.inspect}") unless mime_type =~ %r{\A[-.A-Za-z0-9]+(/[-.A-Za-z0-9]+)*\Z}
        end

    end

  end

end
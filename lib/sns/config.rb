module Sns
  class Config

    # stores the default values for the settings
    # note: key names *must* be declared as strings -- *not* as symbols
    @defaults = { 'stylesheet_directory' => 'css',
                  'javascript_directory' => 'js',
                  'stylesheet_mime_type' => 'text/css',
                  'javascript_mime_type' => 'text/javascript',
                  'cache_timeout'        => 10.minutes
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
          return @defaults[key] unless Radiant::Config.table_exists?
          @@live_config[key] = Radiant::Config["SnS.#{key}"]
          if @@live_config[key].blank?
            @@live_config[key] = Radiant::Config["SnS.#{key}"] = @defaults[key]
          end
        end
        @@live_config[key]
      end


      # Setter for Config key/value pairs.  Keys must be limited to valid
      # settings for the extension.
      def []=(key, value)
        validate_key(key)
        return unless Radiant::Config.table_exists?
        # key must be in the form of a string for Radiant:Config
        key = key.to_s

        case key
          # TODO: Remove directory config entry since Rack cache does not use it.
          when /_directory$/
            value = validate_directory(value, key)
            @@live_config[key] = Radiant::Config["SnS.#{key}"] = value
          when /_mime_type$/
            validate_mime_type(value, key)
            @@live_config[key] = Radiant::Config["SnS.#{key}"] = value
            Radiant::Cache.clear
        end
      end


      def to_hash
        Hash[*@defaults.keys.map { |key| [key, self[key]] }.flatten]
      end


      def restore_defaults
        @defaults.each { |key, value| self[key] = value }
      end


      private

        # determines whether 'key' matches one of the keys in @defaults (
        def validate_key(key)
          raise(%{Invalid setting name: "#{key}"}) unless @defaults.has_key?(key.to_s)
        end


        def validate_directory(directory, directory_label)
          raise(%{Invalid #{directory_label} value: "#{directory}"}) unless directory =~ %r{\A/?[-_A-Za-z0-9]+(/[-_A-Za-z0-9]+)*/?\Z}
          # return value with leading/trailing slashes removed
          directory.gsub(/^\/+/, '').gsub(/\/+$/, '')
        end


        def validate_mime_type(mime_type, mime_type_label)
          raise(%{Invalid #{mime_type_label} value: "#{mime_type}"}) unless mime_type =~ %r{\A[-.A-Za-z0-9]+(/[-.A-Za-z0-9]+)*\Z}
        end

    end

  end
end
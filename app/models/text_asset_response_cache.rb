class TextAssetResponseCache < ResponseCache

  def initialize(options={})
    # Use TEXT_ASSET_CACHE_DIR but strip leading and trailing slashes (if any)
    @@defaults[:directory] = RAILS_ROOT + '/' + 
        TEXT_ASSET_CACHE_DIR.gsub(/^\/+/, '').gsub(/\/+$/, '')
    @@defaults[:expire_time] = 1.year
    super(options)
  end


  def self.instance
    # can't use @@instance as this class is inherited so use: @tarc_instance
    @@tarc_instance ||= new
  end

end

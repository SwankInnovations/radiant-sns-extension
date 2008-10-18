class TextAssetResponseCache < ResponseCache
  def initialize(options={})
    @@defaults[:directory] = "#{RAILS_ROOT}/#{StylesNScripts::Config[:response_cache_directory]}"
    @@defaults[:expire_time] = 1.year
    super(options)
  end

  def self.instance
    # can't use @@instance as this class is inherited
    @@tarc_instance ||= new
  end
end

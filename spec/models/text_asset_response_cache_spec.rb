# This specifies the behavior of the TextAssetResponseCache which controlls the
# caching of stylesheets and javascripts.

require File.dirname(__FILE__) + '/../spec_helper'

describe TextAssetResponseCache do

  class TestResponse < ActionController::TestResponse
    def initialize(body = '', headers = {})
      self.body = body
      self.headers = headers
    end
  end


  before :all do
    @dir = File.expand_path("#{RAILS_ROOT}/test/text_asset_cache")
    @baddir = File.expand_path("#{RAILS_ROOT}/test/bad_text_asset_cache")
    @old_perform_caching = TextAssetResponseCache.defaults[:perform_caching]
    TextAssetResponseCache.defaults[:perform_caching] = true
  end


  before(:each) do
    FileUtils.rm_rf @baddir
    @cache = TextAssetResponseCache.new(
      :directory => @dir,
      :perform_caching => true
    )
    @cache.clear
  end


  after :each do
    FileUtils.rm_rf @dir if File.exists? @dir
  end


  after :all do
    TextAssetResponseCache.defaults[:perform_caching] = @old_preform_caching
  end


  it 'should inherit from the Radiant ResponseCache' do
    @cache.should be_kind_of(ResponseCache)
  end


  it 'should set up its own instance (be independent of the Radiant ResponseCache' do
    @cache.should_not === ResponseCache.instance
  end


  it 'should set cache location to: RAILS_ROOT/TEXT_ASSET_CACHE_DIR' do
    with_warnings_suppressed{TEXT_ASSET_CACHE_DIR = 'another_cache_location'}
    Singleton.send :__init__, TextAssetResponseCache
    TextAssetResponseCache.instance.defaults[:directory].
        should == "#{RAILS_ROOT}/another_cache_location"
  end


  ['/cache_dir', 'cache_dir/', '/cache_dir/', '//cache_dir//'].each do |dir|
    it "should tolerate TEXT_ASSET_CACHE_DIR values with leading or trailing slashes (i.e. #{dir.inspect})" do
      with_warnings_suppressed{TEXT_ASSET_CACHE_DIR = dir}
      Singleton.send :__init__, TextAssetResponseCache
      TextAssetResponseCache.instance.defaults[:directory].
          should == "#{RAILS_ROOT}/cache_dir"
    end
  end


  it 'should have a default cache expiration of 1 year' do
    @cache.defaults[:expire_time].should == 1.year
  end


# These three specs are stolen directly from the response_cache_spec.  Mostly these
# are redundant tests but I at least wanted to ensure that it actually caches
  ['test/me', '/test/me', 'test/me/', '/test/me/', 'test//me'].each do |url|
    it "should cache response for url: #{url.inspect}" do
      @cache.clear
      response = response('content', 'Last-Modified' => 'Tue, 27 Feb 2007 06:13:43 GMT')
      response.cache_timeout = Time.utc(2007, 2, 8, 17, 37, 9)
      @cache.cache_response(url, response)
      name = "#{@dir}/test/me.yml"
      File.exists?(name).should == true
      YAML.load(file(name)).should == {
        'expires' => Time.gm(2007, 2, 8, 17, 37, 9),
        'headers' => {
          'Last-Modified' => 'Tue, 27 Feb 2007 06:13:43 GMT',
          'ETag' => '040f06fd774092478d450774f5ba30c5da78acc8'
        }
      }
      data_name = "#{@dir}/test/me.data"
      file(data_name).should == "content"
    end
  end

  it 'should send 304 response if cached Last-Modified date is older than If-Modified-Since date' do
    last_modified = Time.now.httpdate
    result = @cache.cache_response('test', response('content', 'Last-Modified' => last_modified))
    request = ActionController::TestRequest.new
    request.env = { 'HTTP_IF_MODIFIED_SINCE' => last_modified }
    second_call = @cache.update_response('test', response, request)
    second_call.headers['Status'].should match(/^304/)
    second_call.body.should == ''
    result.should be_kind_of(TestResponse)
  end

  it 'cache response with extension' do
    @cache.cache_response("styles.css", response('content'))
    File.exists?("#{@dir}/styles.css.yml").should == true
  end

end


private

  def file(name)
    open(name) { |f| f.read } rescue ''
  end


  def response(*args)
    TestResponse.new(*args)
  end


  def with_warnings_suppressed
    old_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = old_verbosity
  end
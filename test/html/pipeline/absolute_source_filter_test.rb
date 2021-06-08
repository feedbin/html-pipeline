require "test_helper"

class HTML::Pipeline::AbsoluteSourceFilterTest < Minitest::Test
  AbsoluteSourceFilter = HTML::Pipeline::AbsoluteSourceFilter

  def setup
    @image_base_url = 'http://assets.example.com'
    @image_subpage_base_url = 'http://blog.example.com/a'
    @image_subpage_url = "#{@image_subpage_base_url}/post"
    @options = {
      :image_base_url    => @image_base_url,
      :image_subpage_url => @image_subpage_url
    }
  end

  def test_rewrites_root_posters
    orig = %(<p><video poster="/img.png"></video></p>)
    assert_equal "<p><video poster=\"#{@image_base_url}/img.png\"></video></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_root_urls_with_space
    orig = %(<p><img src="/an img.png"></p>)
    assert_equal "<p><img src=\"#{@image_base_url}/an%20img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_root_urls
    orig = %(<p><img src="/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_base_url}/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_relative_urls
    orig = %(<p><img src="post/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_subpage_base_url}/post/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_relative_urls_data_subdirectory
    orig = %(<p><img src="data/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_subpage_base_url}/data/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_rewrites_relative_urls_http_subdirectory
    orig = %(<p><img src="http/img.png"></p>)
    assert_equal "<p><img src=\"#{@image_subpage_base_url}/http/img.png\"></p>",
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_does_not_rewrite_data_urls
    orig = %(<p><img src="data:image/png;base64,..."></p>)
    result = AbsoluteSourceFilter.call(orig, @options).to_s
    refute_match /@image_base_url/, result
    refute_match /@image_subpage_url/, result
  end

  def test_does_not_rewrite_absolute_https_urls
    orig = %(<p><img src="https://other.example.com/img.png"></p>)
    result = AbsoluteSourceFilter.call(orig, @options).to_s
    refute_match /@image_base_url/, result
    refute_match /@image_subpage_url/, result
  end

  def test_does_not_rewrite_absolute_urls
    orig = %(<p><img src="http://other.example.com/img.png"></p>)
    result = AbsoluteSourceFilter.call(orig, @options).to_s
    refute_match /@image_base_url/, result
    refute_match /@image_subpage_url/, result
  end

  def test_fails_when_context_is_missing
    assert_raises RuntimeError do
      AbsoluteSourceFilter.call("<img src=\"img.png\">", {})
    end
    assert_raises RuntimeError do
      AbsoluteSourceFilter.call("<img src=\"/img.png\">", {})
    end
  end

  def test_tells_you_where_context_is_required
    exception = assert_raises(RuntimeError) {
      AbsoluteSourceFilter.call("<img src=\"img.png\">", {})
    }
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message

    exception = assert_raises(RuntimeError) {
      AbsoluteSourceFilter.call("<img src=\"/img.png\">", {})
    }
    assert_match 'HTML::Pipeline::AbsoluteSourceFilter', exception.message
  end

end

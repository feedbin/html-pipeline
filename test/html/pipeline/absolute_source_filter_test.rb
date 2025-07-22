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

  def test_rewrites_relative_srcsets
    orig = %(<img srcset="/img.png 1x, img2.png 2x, data:example 3x">)
    assert_equal %(<img srcset="#{@image_base_url}/img.png 1x, #{@image_subpage_base_url}/img2.png 2x, data:example 3x">),
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

  def test_srcset_with_width_descriptors
    orig = %(<img srcset="elva-fairy-480w.jpg 480w, elva-fairy-800w.jpg 800w">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/elva-fairy-480w.jpg 480w, #{@image_subpage_base_url}/elva-fairy-800w.jpg 800w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_density_descriptors
    orig = %(<img srcset="image-320w.jpg, image-480w.jpg 1.5x, image-640w.jpg 2x">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image-320w.jpg, #{@image_subpage_base_url}/image-480w.jpg 1.5x, #{@image_subpage_base_url}/image-640w.jpg 2x">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_mixed_absolute_and_relative_urls
    orig = %(<img srcset="https://cdn.example.com/image1.jpg 480w, /images/image2.jpg 800w, relative/image3.jpg 1200w">)
    assert_equal %(<img srcset="https://cdn.example.com/image1.jpg 480w, #{@image_base_url}/images/image2.jpg 800w, #{@image_subpage_base_url}/relative/image3.jpg 1200w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_query_parameters
    orig = %(<img srcset="image.jpg?size=small 480w, image.jpg?size=large 1200w">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image.jpg?size=small 480w, #{@image_subpage_base_url}/image.jpg?size=large 1200w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_spaces_in_urls
    orig = %(<img srcset="image%20with%20spaces.jpg 480w, another%20spaced%20image.jpg 800w">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image%20with%20spaces.jpg 480w, #{@image_subpage_base_url}/another%20spaced%20image.jpg 800w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_complex_cloudflare_urls
    orig = %(<img srcset="/cdn-cgi/image/format=auto,fit=scale-down,width=500,metadata=none/plus/misc/images/xkcd-plants-animals.jpg 500w, /cdn-cgi/image/format=auto,fit=scale-down,width=1200,metadata=none/plus/misc/images/xkcd-plants-animals.jpg 1200w">)
    assert_equal %(<img srcset="#{@image_base_url}/cdn-cgi/image/format=auto,fit=scale-down,width=500,metadata=none/plus/misc/images/xkcd-plants-animals.jpg 500w, #{@image_base_url}/cdn-cgi/image/format=auto,fit=scale-down,width=1200,metadata=none/plus/misc/images/xkcd-plants-animals.jpg 1200w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_decimal_pixel_density
    orig = %(<img srcset="image1.jpg 1.5x, image2.jpg 2.5x">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image1.jpg 1.5x, #{@image_subpage_base_url}/image2.jpg 2.5x">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_extra_whitespace
    orig = %(<img srcset="  image1.jpg   480w  ,   image2.jpg   800w  ">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image1.jpg 480w, #{@image_subpage_base_url}/image2.jpg 800w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_already_absolute_urls
    orig = %(<img srcset="https://cdn.example.com/image1.jpg 480w, https://cdn.example.com/image2.jpg 800w">)
    assert_equal %(<img srcset="https://cdn.example.com/image1.jpg 480w, https://cdn.example.com/image2.jpg 800w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_single_url_without_descriptor
    orig = %(<img srcset="single-image.jpg">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/single-image.jpg">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_trailing_commas_parse_error
    orig = %(<img srcset="image1.jpg, 480w, image2.jpg 800w">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image1.jpg, #{@image_subpage_base_url}/480w, #{@image_subpage_base_url}/image2.jpg 800w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_invalid_descriptors
    orig = %(<img srcset="image1.jpg 0w, image2.jpg 100w">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image1.jpg 0w, #{@image_subpage_base_url}/image2.jpg 100w">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_parentheses_in_descriptors
    orig = %(<img srcset="image.jpg calc(100vw-20px)">)
    assert_equal %(<img srcset="#{@image_subpage_base_url}/image.jpg calc(100vw-20px)">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_empty_srcset
    orig = %(<img srcset="">)
    assert_equal %(<img srcset="">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

  def test_srcset_with_only_whitespace
    orig = %(<img srcset="    ">)
    assert_equal %(<img srcset="">),
      AbsoluteSourceFilter.call(orig, @options).to_s
  end

end

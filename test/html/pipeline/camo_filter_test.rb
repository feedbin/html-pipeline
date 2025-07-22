require "test_helper"

class HTML::Pipeline::CamoFilterTest < Minitest::Test
  CamoFilter = HTML::Pipeline::CamoFilter

  def setup
    @asset_proxy_url        = 'https//assets.example.org'
    @asset_proxy_secret_key = 'ssssh-secret'
    @options = {
      :asset_proxy            => @asset_proxy_url,
      :asset_proxy_secret_key => @asset_proxy_secret_key,
      :asset_proxy_whitelist  => [/(^|\.)github\.com$/]
    }
  end

  def test_asset_proxy_disabled
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_equal orig,
      CamoFilter.call(orig, @options.merge(:disable_asset_proxy => true)).to_s
  end

  def test_camouflaging_http_image_urls
    orig = %(<p><img src="http://twitter.com/img.png"></p>)
    assert_equal %(<p><img src="https//assets.example.org/a5ad43494e343b20d745586282be61ff530e6fa0/687474703a2f2f747769747465722e636f6d2f696d672e706e67" data-canonical-src="http://twitter.com/img.png"></p>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_camouflaging_http_poster_urls
    orig = %(<p><video poster="http://twitter.com/img.png"></video></p>)
    assert_equal %(<p><video data-camo-poster="https//assets.example.org/a5ad43494e343b20d745586282be61ff530e6fa0/687474703a2f2f747769747465722e636f6d2f696d672e706e67" data-canonical-poster="http://twitter.com/img.png"></video></p>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_camouflaging_srcset
    orig = %(<img srcset="http://example.com/img.png 1w, http://example.com/img2.png 2w">)
    assert_equal %(<img data-canonical-srcset="http://example.com/img.png 1w, http://example.com/img2.png 2w" data-camo-srcset="https//assets.example.org/3853c1b066695bf9d725dfc3f760bf940848d83d/687474703a2f2f6578616d706c652e636f6d2f696d672e706e67 1w, https//assets.example.org/11af20abd28eb0bc334c9b63d21d094223724f89/687474703a2f2f6578616d706c652e636f6d2f696d67322e706e67 2w">),
      CamoFilter.call(orig, @options).to_s
  end

  def test_invalid_srcset
    orig = %(<img srcset="/1">)
    assert_equal %(<img>),
      CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_image_urls
    orig = %(<p><img src="https://github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_subdomain_image_urls
    orig = %(<p><img src="https://raw.github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_dotcom_subsubdomain_image_urls
    orig = %(<p><img src="https://f.assets.github.com/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_absolute_image_urls
    orig = %(<p><img src="/img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_doesnt_rewrite_relative_image_urls
    orig = %(<p><img src="img.png"></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_handling_images_with_no_src_attribute
    orig = %(<p><img></p>)
    assert_equal orig, CamoFilter.call(orig, @options).to_s
  end

  def test_required_context_validation
    exception = assert_raises(ArgumentError) {
      CamoFilter.call("", {})
    }
    assert_match /:asset_proxy[^_]/, exception.message
    assert_match /:asset_proxy_secret_key/, exception.message
  end

end

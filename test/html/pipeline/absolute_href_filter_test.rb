require "test_helper"

class HTML::Pipeline::AbsoluteHrefFilterTest < Minitest::Test
  AbsoluteHrefFilter = HTML::Pipeline::AbsoluteHrefFilter

  def setup
    @href_base_url = 'http://www.example.com'
    @href_subpage_url = 'http://blog.example.com/a/post'
    @options = {
      :href_base_url    => @href_base_url,
      :href_subpage_url => @href_subpage_url
    }
  end

  def test_rewrites_root_relative_urls
    orig = %(<p><a href="/link">Link</a></p>)
    assert_equal "<p><a href=\"#{@href_base_url}/link\">Link</a></p>",
      AbsoluteHrefFilter.call(orig, @options).to_s
  end

  def test_rewrites_relative_urls
    orig = %(<p><a href="post/link">Link</a></p>)
    assert_equal "<p><a href=\"#{@href_subpage_url}/link\">Link</a></p>",
      AbsoluteHrefFilter.call(orig, @options).to_s
  end

  def test_does_not_rewrite_absolute_urls
    orig = %(<p><a href="http://other.example.com/link">Link</a></p>)
    result = AbsoluteHrefFilter.call(orig, @options).to_s
    refute_match /@href_base_url/, result
    refute_match /@href_subpage_url/, result
  end

end

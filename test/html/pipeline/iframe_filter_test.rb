require "test_helper"

class HTML::Pipeline::IframeFilterTest < Minitest::Test
  IframeFilter = HTML::Pipeline::IframeFilter

  def setup
    @embed_url = 'http://www.example.com'
    @embed_classes = 'embed'
    @options = {
      embed_url: @embed_url,
      embed_classes: @embed_classes,
    }
  end

  def test_rewrites_iframes
    orig = %(<iframe src="http://embed.example.com" height="9" width="16">)
    replacement = %(<div id="49251cd95fa90bb2acaac1a5a3a17d184ba09f52" class="embed" data-iframe-src="http://embed.example.com" data-iframe-host="embed.example.com" data-iframe-embed-url="http://www.example.com?url=http%3A%2F%2Fembed.example.com&amp;dom_id=49251cd95fa90bb2acaac1a5a3a17d184ba09f52&amp;width=16&amp;height=9" data-iframe-width="16" data-iframe-height="9"></div>)
    assert_equal replacement, IframeFilter.call(orig, @options).to_s
  end

end

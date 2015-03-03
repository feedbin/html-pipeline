require "test_helper"

class HTML::Pipeline::CanonicalSourceFilterTest < Minitest::Test
  CanonicalSourceFilter = HTML::Pipeline::CanonicalSourceFilter

  def test_canonical_src
    src = "http://twitter.com/img.png"
    orig = %(<img src="#{src}">)
    expected = %(<img src="#{src}" data-canonical-src="#{src}">)
    assert_equal expected, CanonicalSourceFilter.call(orig, @options).to_s
  end
end

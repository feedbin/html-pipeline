require "test_helper"

class HTML::Pipeline::LazyLoadFilterTest < Minitest::Test
  LazyLoadFilter = HTML::Pipeline::LazyLoadFilter

  def test_rewrites_root_urls
    original_source = "http://example.com/actual_image.png"
    orig = %(<img src="/img.png" data-original="#{original_source}">)
    assert_equal %(<img src="#{original_source}" data-original="#{original_source}">),
      LazyLoadFilter.call(orig).to_s
  end

end

require "test_helper"

class HTML::Pipeline::LazyLoadFilterTest < Minitest::Test
  LazyLoadFilter = HTML::Pipeline::LazyLoadFilter

  def setup
    @original_source = "http://example.com/actual_image.png"
  end

  def test_data_original
    orig = %(<img src="/img.png" data-original="#{@original_source}">)
    assert_equal %(<img src="#{@original_source}" data-original="#{@original_source}">),
      LazyLoadFilter.call(orig).to_s
  end

  def test_data_canonical_src
    orig = %(<img src="/img.png" data-canonical-src="#{@original_source}">)
    assert_equal %(<img src="#{@original_source}" data-canonical-src="#{@original_source}">),
      LazyLoadFilter.call(orig).to_s
  end

  def test_data_src
    orig = %(<img src="/img.png" data-src="#{@original_source}">)
    assert_equal %(<img src="#{@original_source}" data-src="#{@original_source}">),
      LazyLoadFilter.call(orig).to_s
  end

end

require "test_helper"

class HTML::Pipeline::ImagePlaceholderFilterTest < Minitest::Test
  ImagePlaceholderFilter = HTML::Pipeline::ImagePlaceholderFilter

  def setup
    @options = {
      :placeholder_url       => '/placeholder.png',
      :placeholder_attribute => 'data-original-src',
    }
  end

  def test_image_src_moved
    src = "http://twitter.com/img.png"
    orig = %(<img src="#{src}">)
    expected = %(<img src="#{@options[:placeholder_url]}" #{@options[:placeholder_attribute]}="#{src}">)
    assert_equal expected, ImagePlaceholderFilter.call(orig, @options).to_s
  end
end

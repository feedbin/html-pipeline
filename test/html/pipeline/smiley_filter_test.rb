require "test_helper"

class HTML::Pipeline::SmileyFilterTest < Minitest::Test
  SmileyFilter = HTML::Pipeline::SmileyFilter

  def setup
  end

  def test_converts_image_tag
    orig = %(<img src="http://s.w.org/images/core/emoji/72x72/1f3c3.png" alt="🏃" class="wp-smiley" style="height: 1em; max-height: 1em;" />)
    assert_equal "🏃", SmileyFilter.call(orig).to_s
  end
end

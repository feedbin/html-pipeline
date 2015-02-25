require "test_helper"

class HTML::Pipeline::ProtocolFilterTest < Minitest::Test
  ProtocolFilter = HTML::Pipeline::ProtocolFilter

  def test_rewrites_protocol_relative_sources
    orig = %(<iframe src="//www.youtube.com/embed/DVyPwgC7OpU?rel=0"></iframe>)
    assert_equal "<iframe src=\"http://www.youtube.com/embed/DVyPwgC7OpU?rel=0\"></iframe>",
      ProtocolFilter.call(orig).to_s
  end

end

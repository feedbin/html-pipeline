require "test_helper"

class HTML::Pipeline::LinkButtonTest < Minitest::Test
  LinkButton = HTML::Pipeline::LinkButton

  def test_strip_extra_urls
    orig = %(<a href="example.com">Link</a>)
    assert_equal %(<a href="example.com">Link<span data-behavior="link_actions"></span></a>),
      LinkButton.call(orig).to_s
  end
end

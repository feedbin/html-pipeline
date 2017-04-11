require "test_helper"

class HTML::Pipeline::SrcFixerTest < Minitest::Test
  SrcFixer = HTML::Pipeline::SrcFixer

  def test_strip_extra_urls
    orig = %(<p><img src="https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-1024x491.png%201024w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-300x144.png%20300w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-768x368.png%20768w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-960x460.png%20960w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-1200x575.png%201200w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-415x199.png%20415w"></p>)
    assert_equal %(<p><img src="https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-1024x491.png"></p>),
      SrcFixer.call(orig).to_s
  end

  def test_strip_extra_urls_relative
    orig = %(<p><img src="/wp-content/uploads/2017/03/20215945/Vault_General_07-1024x491.jpg%201024w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-300x144.png%20300w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-768x368.png%20768w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-960x460.png%20960w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-1200x575.png%201200w,%20https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-415x199.png%20415w"></p>)
    assert_equal %(<p><img src="/wp-content/uploads/2017/03/20215945/Vault_General_07-1024x491.jpg"></p>),
      SrcFixer.call(orig).to_s
  end

  def test_skip_match
    orig = %(<p><img src="https://cdn.discoposse.com/wp-content/uploads/2017/03/20215945/Vault_General_07-1024x491.png"></p>)
    assert_equal orig,
      SrcFixer.call(orig).to_s
  end

  def test_empty_src
    orig = %(<p><img></p>)
    assert_equal orig,
      SrcFixer.call(orig).to_s
  end
end

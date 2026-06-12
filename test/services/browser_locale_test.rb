require "test_helper"

class BrowserLocaleTest < ActiveSupport::TestCase
  test "selects Brazilian Portuguese when accepted" do
    assert_equal :"pt-BR", BrowserLocale.resolve("pt-BR,pt;q=0.9,en;q=0.8")
  end

  test "uses the default locale for unsupported languages" do
    assert_equal I18n.default_locale, BrowserLocale.resolve("es-ES,es;q=0.9")
  end

  test "ignores Brazilian Portuguese with zero quality" do
    assert_equal I18n.default_locale, BrowserLocale.resolve("pt-BR;q=0,en;q=1")
  end
end

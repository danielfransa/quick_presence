require "test_helper"

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  test "shows the privacy notice page" do
    get privacy_url

    assert_response :success
    assert_includes response.body, I18n.t("privacy.show.title")
    assert_includes response.body, I18n.t("privacy.show.not_used.title")
  end
end

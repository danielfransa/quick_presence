require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the public home page" do
    get root_url

    assert_response :success
    assert_includes response.body, I18n.t("app.name")
    assert_includes response.body, I18n.t("layouts.application.privacy_notice.title")
    assert_select "a[href='#{privacy_path}']"
  end
end

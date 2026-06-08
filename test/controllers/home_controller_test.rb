require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the public home page" do
    get root_url

    assert_response :success
    assert_includes response.body, "QuickPresence"
  end
end

require "test_helper"

class DevisePagesTest < ActionDispatch::IntegrationTest
  test "renders sign up page with Bootstrap card" do
    get new_user_registration_url

    assert_response :success
    assert_includes response.body, "Create your account"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "renders sign in page with Bootstrap card" do
    get new_user_session_url

    assert_response :success
    assert_includes response.body, "Sign in"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "renders password reset page with Bootstrap card" do
    get new_user_password_url

    assert_response :success
    assert_includes response.body, "Reset your password"
    assert_includes response.body, "card border-0 shadow-sm"
  end
end

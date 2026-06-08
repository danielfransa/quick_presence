require "test_helper"

class DevisePagesTest < ActionDispatch::IntegrationTest
  test "renders sign up page with Bootstrap card" do
    get new_user_registration_url

    assert_response :success
    assert_includes response.body, "Create your account"
    assert_includes response.body, "Username"
    assert_includes response.body, "Password recovery and password changes are not available"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "renders sign in page with Bootstrap card" do
    get new_user_session_url

    assert_response :success
    assert_includes response.body, "Sign in"
    assert_includes response.body, "Username"
    assert_includes response.body, "Password recovery is not available"
    assert_not_includes response.body, "Forgot your password?"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "creates an account with username instead of email" do
    assert_difference "User.count", 1 do
      post user_registration_url, params: {
        user: {
          username: "new_organizer",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to attendance_lists_url
    assert User.exists?(username: "new_organizer")
  end
end

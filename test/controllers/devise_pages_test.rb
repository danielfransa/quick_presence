require "test_helper"

class DevisePagesTest < ActionDispatch::IntegrationTest
  test "renders sign up page with Bootstrap card" do
    get new_user_registration_url

    assert_response :success
    assert_includes response.body, I18n.t("accounts.registrations.new.title")
    assert_includes response.body, User.human_attribute_name(:username)
    assert_includes response.body, I18n.t("accounts.registrations.new.password_warning")
    assert_includes response.body, "120 days"
    assert_includes response.body, "inactivity_terms_accepted"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "renders sign in page with Bootstrap card" do
    get new_user_session_url

    assert_response :success
    assert_includes response.body, I18n.t("accounts.sessions.new.title")
    assert_includes response.body, User.human_attribute_name(:username)
    assert_includes response.body, I18n.t("accounts.sessions.new.password_warning")
    assert_not_includes response.body, "Forgot your password?"
    assert_includes response.body, "card border-0 shadow-sm"
  end

  test "creates an account with username instead of email" do
    assert_difference "User.count", 1 do
      post user_registration_url, params: {
        user: {
          username: "new_organizer",
          password: "password123",
          password_confirmation: "password123",
          inactivity_terms_accepted: "1"
        }
      }
    end

    assert_redirected_to attendance_lists_url
    user = User.find_by!(username: "new_organizer")
    assert_not_nil user.inactivity_terms_accepted_at
    assert_not_nil user.last_login_at
  end

  test "does not create an account without accepting inactivity deletion" do
    assert_no_difference "User.count" do
      post user_registration_url, params: {
        user: {
          username: "new_organizer",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("errors.messages.accepted")
  end

  test "records the last successful login" do
    user = users(:organizer)
    user.update_columns(last_login_at: 5.days.ago)

    post user_session_url, params: {
      user: {
        username: user.username,
        password: "password123"
      }
    }

    assert_redirected_to attendance_lists_url
    assert_in_delta Time.current, user.reload.last_login_at, 2.seconds
  end

  test "shows account deletion consequences in a confirmation modal" do
    sign_in users(:organizer)

    get edit_user_registration_url

    assert_response :success
    assert_includes response.body, "deleteAccountModal"
    assert_includes response.body, I18n.t("accounts.registrations.edit.delete.lists_item")
    assert_includes response.body, I18n.t("accounts.registrations.edit.delete.responses_item")
  end

  test "deletes the account and all related data then signs the user out" do
    user = users(:organizer)
    attendance_list_ids = user.attendance_list_ids
    sign_in user

    assert_difference -> { User.count }, -1 do
      delete user_registration_url
    end

    assert_redirected_to account_deleted_url
    assert_not AttendanceList.where(id: attendance_list_ids).exists?
    assert_not AttendanceResponse.where(attendance_list_id: attendance_list_ids).exists?

    follow_redirect!
    assert_response :success
    assert_includes response.body, I18n.t("accounts.deleted.description")

    get attendance_lists_url
    assert_redirected_to new_user_session_url
  end
end

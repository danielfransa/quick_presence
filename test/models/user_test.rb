require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has many attendance lists" do
    assert_includes users(:organizer).attendance_lists, attendance_lists(:open_list)
  end

  test "requires a valid username" do
    user = User.new(
      username: "bad name",
      password: "password123",
      password_confirmation: "password123",
      inactivity_terms_accepted: "1"
    )

    assert_not user.valid?
    assert_includes user.errors[:username], I18n.t("activerecord.errors.models.user.attributes.username.invalid_format")
  end

  test "normalizes username before validation" do
    user = User.new(
      username: " Organizer_New ",
      password: "password123",
      password_confirmation: "password123",
      inactivity_terms_accepted: "1"
    )

    assert user.valid?
    assert_equal "organizer_new", user.username
  end

  test "requires acceptance of the inactivity deletion term" do
    user = User.new(
      username: "new_user",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert_includes user.errors[:inactivity_terms_accepted], I18n.t("errors.messages.accepted")
  end
end

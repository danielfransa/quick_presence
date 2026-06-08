require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has many attendance lists" do
    assert_includes users(:organizer).attendance_lists, attendance_lists(:open_list)
  end

  test "requires a valid username" do
    user = User.new(username: "bad name", password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:username], "can only contain letters, numbers, and underscores"
  end

  test "normalizes username before validation" do
    user = User.new(username: " Organizer_New ", password: "password123", password_confirmation: "password123")

    assert user.valid?
    assert_equal "organizer_new", user.username
  end
end

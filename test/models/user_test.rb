require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has many attendance lists" do
    assert_includes users(:organizer).attendance_lists, attendance_lists(:open_list)
  end
end

require "test_helper"

class AttendanceResponseTest < ActiveSupport::TestCase
  test "sets submitted_at on create" do
    response = attendance_lists(:open_list).attendance_responses.create!

    assert response.submitted_at.present?
  end

  test "rejects responses when attendance list is closed" do
    response = attendance_lists(:closed_list).attendance_responses.new

    assert_not response.valid?
    assert_includes response.errors[:base], "Attendance list is closed"
  end
end

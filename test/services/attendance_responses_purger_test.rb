require "test_helper"

class AttendanceResponsesPurgerTest < ActiveSupport::TestCase
  test "deletes responses and answers while resetting counters" do
    attendance_list = attendance_lists(:open_list)
    attendance_response_id = attendance_responses(:first_response).id

    assert_equal 1, AttendanceResponsesPurger.call(AttendanceList.where(id: attendance_list.id))
    assert_not AttendanceResponse.where(attendance_list: attendance_list).exists?
    assert_not AttendanceAnswer.where(attendance_response_id: attendance_response_id).exists?
    assert_equal 0, attendance_list.reload.attendance_responses_count
  end

  test "does nothing when the relation has no responses" do
    assert_equal 0, AttendanceResponsesPurger.call(AttendanceList.none)
  end
end

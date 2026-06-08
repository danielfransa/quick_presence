require "test_helper"

class PurgeExpiredAttendanceResponsesJobTest < ActiveJob::TestCase
  test "purges responses for lists past the retention window" do
    attendance_list = attendance_lists(:open_list)
    attendance_list.update_columns(ends_at: 49.hours.ago)

    assert_difference -> { AttendanceResponse.count }, -1 do
      assert_difference -> { AttendanceAnswer.count }, -2 do
        PurgeExpiredAttendanceResponsesJob.perform_now
      end
    end
  end

  test "keeps responses inside the retention window" do
    attendance_list = attendance_lists(:open_list)
    attendance_list.update_columns(ends_at: 47.hours.ago)

    assert_no_difference -> { AttendanceResponse.count } do
      PurgeExpiredAttendanceResponsesJob.perform_now
    end
  end
end

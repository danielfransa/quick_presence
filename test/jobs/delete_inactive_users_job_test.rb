require "test_helper"

class DeleteInactiveUsersJobTest < ActiveJob::TestCase
  test "deletes users who have not logged in for 120 days and all related data" do
    user = users(:organizer)
    attendance_list_ids = user.attendance_list_ids
    user.update_columns(last_login_at: 120.days.ago)

    assert_difference -> { User.count }, -1 do
      DeleteInactiveUsersJob.perform_now
    end

    assert_not User.exists?(user.id)
    assert_not AttendanceList.where(id: attendance_list_ids).exists?
    assert_not AttendanceResponse.where(attendance_list_id: attendance_list_ids).exists?
  end

  test "keeps users who logged in less than 120 days ago" do
    users(:organizer).update_columns(last_login_at: 119.days.ago)

    assert_no_difference -> { User.count } do
      DeleteInactiveUsersJob.perform_now
    end
  end
end

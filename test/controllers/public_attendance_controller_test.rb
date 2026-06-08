require "test_helper"

class PublicAttendanceControllerTest < ActionDispatch::IntegrationTest
  test "shows an open public attendance form" do
    get public_attendance_url(attendance_lists(:open_list).public_token)

    assert_response :success
    assert_includes response.body, attendance_lists(:open_list).title
  end

  test "shows closed state for a closed public attendance form" do
    get public_attendance_url(attendance_lists(:closed_list).public_token)

    assert_response :success
    assert_includes response.body, "This attendance list has expired"
  end

  test "records a public attendance response" do
    assert_difference -> { AttendanceResponse.count }, 1 do
      post public_attendance_url(attendance_lists(:open_list).public_token), params: {
        answers: {
          attendance_fields(:student_name).id.to_s => "Grace Hopper",
          attendance_fields(:student_code).id.to_s => "G456"
        }
      }
    end

    assert_redirected_to public_attendance_url(attendance_lists(:open_list).public_token)
  end

  test "does not record a response for a closed list" do
    assert_no_difference -> { AttendanceResponse.count } do
      post public_attendance_url(attendance_lists(:closed_list).public_token), params: {
        answers: {}
      }
    end

    assert_redirected_to public_attendance_url(attendance_lists(:closed_list).public_token)
  end
end

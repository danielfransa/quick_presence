require "test_helper"

class AttendanceListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:organizer)
  end

  test "shows current user's attendance lists" do
    get attendance_lists_url

    assert_response :success
    assert_includes response.body, attendance_lists(:open_list).title
  end

  test "shows five custom field slots on new form" do
    get new_attendance_list_url

    assert_response :success
    assert_equal 5, response.body.scan(/placeholder="Name, Student code, Class..."/).size
    assert_includes response.body, "Timestamp is automatic"
    assert_includes response.body, "Time zone detected automatically"
    assert_includes response.body, 'name="attendance_list[time_zone]"'
  end

  test "shows an owned attendance list" do
    get attendance_list_url(attendance_lists(:open_list))

    assert_response :success
    assert_includes response.body, "Public link"
  end

  test "does not show another user's attendance list" do
    get attendance_list_url(attendance_lists(:closed_list))

    assert_response :not_found
  end

  test "creates an attendance list with custom fields" do
    assert_difference -> { AttendanceList.count }, 1 do
      post attendance_lists_url, params: {
        attendance_list: {
          title: "Operating Systems",
          description: "Weekly class attendance",
          time_zone: "America/Los_Angeles",
          starts_at_local: "2026-06-08T15:00",
          ends_at_local: "2026-06-08T15:15",
          active: "1",
          attendance_fields_attributes: {
            "0" => { label: "Name", field_type: "text", required: "1", position: "0" },
            "1" => { label: "Student code", field_type: "text", required: "0", position: "1" }
          }
        }
      }
    end

    attendance_list = AttendanceList.order(:created_at).last

    assert_equal "America/Los_Angeles", attendance_list.time_zone
    assert_equal "2026-06-08T15:00", attendance_list.starts_at_local
    assert_redirected_to attendance_list_url(attendance_list)
  end

  test "closes an attendance list" do
    patch close_attendance_list_url(attendance_lists(:open_list))

    assert_redirected_to attendance_list_url(attendance_lists(:open_list))
    assert_not attendance_lists(:open_list).reload.open?
  end

  test "exports responses as csv" do
    get export_attendance_list_url(attendance_lists(:open_list))

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Timestamp,Name,Student code"
  end

  test "exports QR code as pdf" do
    get qr_code_pdf_attendance_list_url(attendance_lists(:open_list))

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "does not export another user's QR code pdf" do
    get qr_code_pdf_attendance_list_url(attendance_lists(:closed_list))

    assert_response :not_found
  end
end

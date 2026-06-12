require "test_helper"

class AttendanceListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:organizer)
  end

  test "shows current user's attendance lists" do
    sql_statements = capture_sql { get attendance_lists_url }

    assert_response :success
    assert_includes response.body, I18n.t("layouts.application.navigation.attendance_lists")
    assert_includes response.body, I18n.t("layouts.application.navigation.log_out")
    assert_not_includes response.body, "collapse navbar-collapse"
    assert_includes response.body, attendance_lists(:open_list).title
    assert_not sql_statements.any? { |sql| sql.match?(/COUNT\(.+\).*attendance_responses/i) }
  end

  test "shows five custom field slots on new form" do
    get new_attendance_list_url

    assert_response :success
    assert_equal 5, response.body.scan(/placeholder="#{Regexp.escape(I18n.t("attendance_lists.form.field_placeholder"))}"/).size
    assert_includes response.body, I18n.t("attendance_lists.form.timestamp_automatic")
    assert_includes response.body, I18n.t("attendance_lists.form.time_zone_detected")
    assert_includes response.body, 'name="attendance_list[time_zone]"'
  end

  test "shows an owned attendance list" do
    get attendance_list_url(attendance_lists(:open_list))

    assert_response :success
    assert_includes response.body, I18n.t("attendance_lists.show.sharing.public_link")
    assert_includes response.body, I18n.t("attendance_lists.show.sharing.copy_link")
    assert_includes response.body, "data-copy-public-link"
    assert_includes response.body, "data-public-link-status"
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
    get export_attendance_list_url(attendance_lists(:open_list), format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    rows = CSV.parse(response.body)

    assert_equal [
      I18n.t("exports.attendance_list.columns.number"),
      "Name",
      "Student code",
      I18n.t("exports.attendance_list.columns.timestamp")
    ], rows.first
    assert_equal [ "1", "Ada Lovelace", "A123" ], rows.second.first(3)
    assert_match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/, rows.second.last)
  end

  test "numbers exported responses in submission order" do
    attendance_list = attendance_lists(:open_list)
    attendance_response = attendance_list.attendance_responses.create!(
      submitted_at: 5.minutes.ago,
      ip_address: "127.0.0.2",
      user_agent: "Rails test"
    )
    attendance_response.attendance_answers.create!(
      attendance_field: attendance_fields(:student_name),
      value: "Grace Hopper"
    )

    get export_attendance_list_url(attendance_list, format: :csv)

    rows = CSV.parse(response.body)
    assert_equal [ "1", "Ada Lovelace" ], rows.second.first(2)
    assert_equal [ "2", "Grace Hopper" ], rows.third.first(2)
  end

  test "exports responses as excel workbook" do
    get export_attendance_list_url(attendance_lists(:open_list), format: :xlsx)

    assert_response :success
    assert_equal AttendanceListXlsx::CONTENT_TYPE, response.media_type
    assert response.body.start_with?("PK")

    Zip::File.open_buffer(response.body) do |workbook|
      worksheet = workbook.read("xl/worksheets/sheet1.xml")

      assert_operator worksheet.index(I18n.t("exports.attendance_list.columns.number")), :<, worksheet.index("Name")
      assert_operator worksheet.index("Student code"), :<, worksheet.index(I18n.t("exports.attendance_list.columns.timestamp"))
      assert_includes worksheet, ">1<"
      assert_includes worksheet, I18n.t("exports.attendance_list.columns.timestamp")
      assert_includes worksheet, "Ada Lovelace"
      assert_includes worksheet, "A123"
    end
  end

  test "purges expired responses before csv export" do
    attendance_lists(:open_list).update_columns(ends_at: 49.hours.ago)

    assert_difference -> { AttendanceResponse.count }, -1 do
      get export_attendance_list_url(attendance_lists(:open_list), format: :csv)
    end

    assert_response :success
    assert_equal [
      I18n.t("exports.attendance_list.columns.number"),
      "Name",
      "Student code",
      I18n.t("exports.attendance_list.columns.timestamp")
    ].to_csv, response.body
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

  private

  def capture_sql
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      statements << payload[:sql] unless payload[:name] == "SCHEMA"
    end

    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

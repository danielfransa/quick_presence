require "test_helper"

class AttendanceAnswerTest < ActiveSupport::TestCase
  test "requires a value for required fields" do
    answer = AttendanceAnswer.new(
      attendance_response: attendance_responses(:first_response),
      attendance_field: attendance_fields(:student_name),
      value: ""
    )

    assert_not answer.valid?
    assert_includes answer.errors[:value], I18n.t("errors.messages.blank")
  end

  test "allows blank values for optional fields" do
    response = attendance_lists(:open_list).attendance_responses.create!

    answer = AttendanceAnswer.new(
      attendance_response: response,
      attendance_field: attendance_fields(:student_code),
      value: ""
    )

    assert answer.valid?
  end
end

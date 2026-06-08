require "test_helper"

class AttendanceFieldTest < ActiveSupport::TestCase
  test "requires a supported field type" do
    field = attendance_fields(:student_name)
    field.field_type = "number"

    assert_not field.valid?
  end

  test "orders fields by position and id" do
    assert_equal [ attendance_fields(:student_name), attendance_fields(:student_code) ],
      attendance_lists(:open_list).attendance_fields.ordered.to_a
  end
end

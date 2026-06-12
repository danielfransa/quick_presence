require "test_helper"

class AttendanceListExportTest < ActiveSupport::TestCase
  test "builds CSV rows in chronological field order" do
    csv = AttendanceListExport.new(attendance_lists(:open_list)).to_csv
    rows = CSV.parse(csv)

    assert_equal [
      I18n.t("exports.attendance_list.columns.number"),
      "Name",
      "Student code",
      I18n.t("exports.attendance_list.columns.timestamp")
    ], rows.first
    assert_equal [ "1", "Ada Lovelace", "A123" ], rows.second.first(3)
  end

  test "builds an XLSX workbook" do
    workbook = AttendanceListExport.new(attendance_lists(:open_list)).to_xlsx

    assert workbook.start_with?("PK")
  end
end

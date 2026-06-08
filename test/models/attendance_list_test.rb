require "test_helper"

class AttendanceListTest < ActiveSupport::TestCase
  test "generates a public token on create" do
    attendance_list = users(:organizer).attendance_lists.create!(title: "Algorithms")

    assert attendance_list.public_token.present?
  end

  test "interprets local datetime fields in the list time zone" do
    attendance_list = users(:organizer).attendance_lists.create!(
      title: "Paris Workshop",
      time_zone: "Paris",
      starts_at_local: "2026-06-08T15:00",
      ends_at_local: "2026-06-08T15:15"
    )

    assert_equal "Paris", attendance_list.time_zone
    assert_equal "2026-06-08T15:00", attendance_list.starts_at_local
    assert_equal "2026-06-08T15:15", attendance_list.ends_at_local
    assert_equal "2026-06-08 13:00:00 UTC", attendance_list.starts_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z")
  end

  test "is open when active and inside the validity window" do
    assert attendance_lists(:open_list).open?
  end

  test "is closed after the validity window" do
    assert attendance_lists(:closed_list).closed?
  end

  test "knows when it has not started yet" do
    attendance_list = users(:organizer).attendance_lists.create!(
      title: "Future List",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )

    assert attendance_list.not_started?
    assert_not attendance_list.open?
  end

  test "knows when it has expired" do
    assert attendance_lists(:closed_list).expired?
  end

  test "requires end date to be after start date" do
    attendance_list = users(:organizer).attendance_lists.new(
      title: "Invalid Window",
      starts_at: Time.current,
      ends_at: 1.minute.ago
    )

    assert_not attendance_list.valid?
    assert_includes attendance_list.errors[:ends_at], "must be after the start date and time"
  end

  test "allows at most five custom fields" do
    attendance_list = users(:organizer).attendance_lists.new(title: "Too Many Fields")

    6.times do |index|
      attendance_list.attendance_fields.build(label: "Field #{index}", position: index)
    end

    assert_not attendance_list.valid?
    assert_includes attendance_list.errors[:attendance_fields], "allows at most 5 fields"
  end
end

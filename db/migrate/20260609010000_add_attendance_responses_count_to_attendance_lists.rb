class AddAttendanceResponsesCountToAttendanceLists < ActiveRecord::Migration[8.1]
  def up
    add_column :attendance_lists, :attendance_responses_count, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE attendance_lists
      SET attendance_responses_count = (
        SELECT COUNT(*)
        FROM attendance_responses
        WHERE attendance_responses.attendance_list_id = attendance_lists.id
      )
    SQL
  end

  def down
    remove_column :attendance_lists, :attendance_responses_count
  end
end

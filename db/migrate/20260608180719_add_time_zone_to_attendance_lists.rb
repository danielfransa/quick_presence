class AddTimeZoneToAttendanceLists < ActiveRecord::Migration[8.1]
  def change
    add_column :attendance_lists, :time_zone, :string, null: false, default: "America/Sao_Paulo"
  end
end

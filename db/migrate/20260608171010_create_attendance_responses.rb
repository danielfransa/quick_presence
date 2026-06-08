class CreateAttendanceResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_responses do |t|
      t.references :attendance_list, null: false, foreign_key: true
      t.datetime :submitted_at, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :attendance_responses, [ :attendance_list_id, :submitted_at ]
  end
end

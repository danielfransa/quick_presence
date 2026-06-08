class CreateAttendanceAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_answers do |t|
      t.references :attendance_response, null: false, foreign_key: true
      t.references :attendance_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :attendance_answers,
      [ :attendance_response_id, :attendance_field_id ],
      unique: true
  end
end

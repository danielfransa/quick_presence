class CreateAttendanceFields < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_fields do |t|
      t.references :attendance_list, null: false, foreign_key: true
      t.string :label, null: false
      t.string :field_type, null: false, default: "text"
      t.boolean :required, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :attendance_fields, [ :attendance_list_id, :position ]
  end
end

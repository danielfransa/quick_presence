class CreateAttendanceLists < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :public_token, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :attendance_lists, :public_token, unique: true
  end
end

class AddInactivityTrackingToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :inactivity_terms_accepted_at, :datetime
    add_column :users, :last_login_at, :datetime

    execute <<~SQL.squish
      UPDATE users
      SET inactivity_terms_accepted_at = CURRENT_TIMESTAMP,
          last_login_at = CURRENT_TIMESTAMP
    SQL

    change_column_null :users, :inactivity_terms_accepted_at, false
    change_column_null :users, :last_login_at, false
    add_index :users, :last_login_at
  end

  def down
    remove_index :users, :last_login_at
    remove_columns :users, :inactivity_terms_accepted_at, :last_login_at
  end
end

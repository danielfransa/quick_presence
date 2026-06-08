class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :username, :string

    execute <<~SQL.squish
      UPDATE users
      SET username = 'user_' || id
      WHERE username IS NULL OR username = ''
    SQL

    change_column_null :users, :username, false
    add_index :users, :username, unique: true

    remove_index :users, :email
    change_column_null :users, :email, true
    change_column_default :users, :email, from: "", to: nil

    remove_index :users, :reset_password_token
    remove_columns :users, :reset_password_token, :reset_password_sent_at
  end

  def down
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_index :users, :reset_password_token, unique: true

    change_column_default :users, :email, from: nil, to: ""

    execute <<~SQL.squish
      UPDATE users
      SET email = username || '@example.invalid'
      WHERE email IS NULL OR email = ''
    SQL

    change_column_null :users, :email, false
    add_index :users, :email, unique: true

    remove_index :users, :username
    remove_column :users, :username
  end
end

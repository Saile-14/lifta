class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :admin, :boolean, null: false, default: false
    add_column :users, :public_profile, :boolean, null: false, default: false
    add_column :users, :time_zone, :string, null: false, default: "Etc/UTC"
    add_column :users, :username, :string

    # Existing accounts get a placeholder they can change in settings. They
    # stay off the leaderboard (public_profile false) since they never opted in.
    execute "UPDATE users SET username = 'lifter' || id"
    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end

  def down
    remove_index :users, :username
    remove_column :users, :username
    remove_column :users, :time_zone
    remove_column :users, :public_profile
    remove_column :users, :admin
  end
end

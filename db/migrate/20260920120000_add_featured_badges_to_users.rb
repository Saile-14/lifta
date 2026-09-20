class AddFeaturedBadgesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :featured_badges, :json, default: [], null: false
  end
end

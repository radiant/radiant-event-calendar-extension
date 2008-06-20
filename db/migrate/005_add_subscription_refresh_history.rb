class AddSubscriptionRefreshHistory < ActiveRecord::Migration
  def self.up
    add_column :calendars, :last_refresh_count, :integer
    add_column :calendars, :last_refresh_date, :datetime
  end

  def self.down
    remove_column :calendars, :last_refresh_count
    remove_column :calendars, :last_refresh_date
  end
end

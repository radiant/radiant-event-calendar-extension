class RefreshInterval < ActiveRecord::Migration
  def self.up
    add_column :icals, :ical_refresh_interval, :integer
    Radiant::Config['event_calendar.default_refresh_interval'] = 3600
  end
  def self.down
    remove_column :icals, :ical_refresh_interval
  end
end
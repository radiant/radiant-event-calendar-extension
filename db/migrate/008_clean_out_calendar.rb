class CleanOutCalendar < ActiveRecord::Migration
  def self.up
    remove_column :calendars, :ical_url
    remove_column :calendars, :last_refresh_date
    remove_column :calendars, :last_refresh_count
  end
  def self.down
    add_colum :calendars, :ical_url, :string
    add_column :calendars, :last_refresh_date, :datetime
    add_column :calendars, :last_refresh_count, :integer
  end
end
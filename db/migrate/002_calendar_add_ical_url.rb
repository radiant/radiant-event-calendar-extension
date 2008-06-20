class CalendarAddIcalUrl < ActiveRecord::Migration
  def self.up
    add_column :calendars, :ical_url, :string
  end

  def self.down
    remove_column :calendars, :ical_url
  end
end

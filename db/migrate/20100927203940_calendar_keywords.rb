class CalendarKeywords < ActiveRecord::Migration
  def self.up
    add_column :calendars, :keywords, :string
    add_column :event_venues, :keywords, :string
    add_column :event_venues, :location, :string
    add_index :event_venues, :location
  end

  def self.down
    remove_column :calendars, :keywords
    remove_column :event_venues, :keywords
    remove_column :event_venues, :location
  end
end

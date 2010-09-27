class CalendarKeywords < ActiveRecord::Migration
  def self.up
    add_column :calendars, :keywords, :string
  end

  def self.down
    remove_column :calendars, :keywords
  end
end

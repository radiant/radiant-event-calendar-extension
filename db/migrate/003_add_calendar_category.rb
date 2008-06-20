class AddCalendarCategory < ActiveRecord::Migration
  def self.up
    add_column :calendars, :category, :string
  end

  def self.down
    remove_column :calendars, :category
  end
end

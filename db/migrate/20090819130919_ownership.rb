class Ownership < ActiveRecord::Migration
  def self.up
    add_column :calendars, :created_by, :integer
    add_column :calendars, :updated_by, :integer
    add_column :calendars, :created_at, :datetime
    add_column :calendars, :updated_at, :datetime
    add_column :calendars, :lock_version, :integer
  end

  def self.down
    remove_column :calendars, :created_by
    remove_column :calendars, :updated_by
    remove_column :calendars, :created_at
    remove_column :calendars, :updated_at
    remove_column :calendars, :lock_version
  end                                      
end                                        

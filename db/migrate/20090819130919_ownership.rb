class Ownership < ActiveRecord::Migration
  def self.up
    add_column :calendars, :created_by, :integer
    add_column :calendars, :updated_by, :integer
    add_column :calendars, :created_at, :datetime
    add_column :calendars, :updated_at, :datetime
    add_column :calendars, :lock_version, :integer
    add_column :calendars, :site_id, :integer
  end

  def self.down
    remove_column :calendars, :created_by
    remove_column :calendars, :updated_by
    remove_column :calendars, :created_at
    remove_column :calendars, :updated_at
    remove_column :calendars, :lock_version
    remove_column :calendars, :site_id
  end                                      
end                                        

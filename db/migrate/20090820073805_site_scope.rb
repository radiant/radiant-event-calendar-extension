class SiteScope < ActiveRecord::Migration
  def self.up
    add_column :calendars, :site_id, :integer
    add_column :events, :site_id, :integer
    add_column :icals, :site_id, :integer
  end

  def self.down
    remove_column :calendars, :site_id
    remove_column :events, :site_id
    remove_column :icals, :site_id
  end
end

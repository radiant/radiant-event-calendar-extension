class SimplerIcalColumns < ActiveRecord::Migration
  def self.up
    rename_column :icals, :ical_url, :url
    rename_column :icals, :ical_username, :username
    rename_column :icals, :ical_password, :password
    rename_column :icals, :ical_use_https, :use_https
    rename_column :icals, :ical_refresh_interval, :refresh_interval
  end

  def self.down
    rename_column :icals, :url, :ical_url
    rename_column :icals, :username, :ical_username
    rename_column :icals, :password, :ical_password
    rename_column :icals, :use_https, :ical_use_https
    rename_column :icals, :refresh_interval, :ical_refresh_interval
  end
end

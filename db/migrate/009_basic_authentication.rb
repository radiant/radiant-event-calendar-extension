class BasicAuthentication < ActiveRecord::Migration
  def self.up
    add_column :icals, :ical_username, :string
    add_column :icals, :ical_password, :string
    add_column :icals, :ical_use_https, :boolean
  end
  def self.down
    remove_column :icals, :ical_username
    remove_column :icals, :ical_password
    remove_column :icals, :ical_use_https
  end
end
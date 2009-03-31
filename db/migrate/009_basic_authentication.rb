class BasicAuthentication < ActiveRecord::Migration
  def self.up
    add_column :icals, :ical_username, :string
    add_column :icals, :ical_password, :string
  end
  def self.down
    remove_column :icals, :ical_username
    remove_column :icals, :ical_password
  end
end
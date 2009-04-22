class MoreProperties < ActiveRecord::Migration
  def self.up
    add_column :events, :url, :string
  end
  def self.down
    remove_column :events, :url
  end
end
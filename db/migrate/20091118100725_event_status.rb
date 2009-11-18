class EventStatus < ActiveRecord::Migration
  def self.up
    add_column :events, :status_id, :integer, :default => 1, :null => false
  end

  def self.down
    remove_column :events, :status_id
  end
end

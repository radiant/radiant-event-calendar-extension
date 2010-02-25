class Occurrences < ActiveRecord::Migration
  def self.up
    add_column :events, :master_id, :integer
    Event.reset_column_information
    Event.find(:all).each do |event|
      event.send :update_occurrences
    end
  end

  def self.down
    remove_column :events, :master_id
  end
end

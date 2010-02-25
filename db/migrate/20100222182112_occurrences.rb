class Occurrences < ActiveRecord::Migration
  def self.up
    add_column :events, :master_id, :integer
  end

  def self.down
    remove_column :events, :master_id
  end
end

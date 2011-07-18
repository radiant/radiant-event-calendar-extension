class Facebook < ActiveRecord::Migration
  def self.up
    add_column :events, :facebook_id, :string
  end

  def self.down
    remove_column :events, :facebook_id
  end
end

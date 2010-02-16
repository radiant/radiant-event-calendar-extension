class MoreEventData < ActiveRecord::Migration
  def self.up
    add_column :events, :uuid, :string, :null => false
    add_column :events, :recurrence, :string
    add_column :events, :priority, :string
    add_column :events, :keywords, :string
    add_column :events, :contact, :string
    add_column :events, :postcode, :string
    add_column :events, :lock_version, :integer
    add_index :events, :uuid, :unique => true
  end

  def self.down
    remove_column :events, :uuid
    remove_column :events, :recurrence
    remove_column :events, :priority
    remove_column :events, :keywords
    remove_column :events, :contact
    remove_column :events, :postcode
    remove_column :events, :lock_version
  end
end

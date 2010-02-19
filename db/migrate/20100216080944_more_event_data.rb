class MoreEventData < ActiveRecord::Migration
  def self.up
    add_column :events, :uuid, :string, :null => false
    add_column :events, :recurrence_rule, :string
    add_column :events, :all_day, :boolean
    add_column :events, :priority, :string
    add_column :events, :keywords, :string
    add_column :events, :contact, :string
    add_column :events, :postcode, :string
    add_column :events, :lock_version, :integer
    add_column :events, :created_by_id, :integer
    add_column :events, :created_at, :datetime
    add_column :events, :updated_by_id, :integer
    add_column :events, :updated_at, :datetime
    add_index :events, :uuid, :unique => true
  end

  def self.down
    remove_column :events, :uuid
    remove_column :events, :recurrence_rule
    remove_column :events, :all_day
    remove_column :events, :priority
    remove_column :events, :keywords
    remove_column :events, :contact
    remove_column :events, :postcode
    remove_column :events, :lock_version
    remove_column :events, :created_by_id
    remove_column :events, :created_at
    remove_column :events, :updated_by_id
    remove_column :events, :updated_at
  end
end

class RecurrenceRules < ActiveRecord::Migration
  def self.up
    create_table :event_recurrence_rules do |t|
      t.column :event_id, :integer
      t.column :active, :boolean
      t.column :period, :string
      t.column :basis, :string
      t.column :interval, :integer, :default => 1
      t.column :limiting_date, :datetime
      t.column :limiting_count, :integer 
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :lock_version, :integer
      t.column :site_id, :integer
    end
    add_index :event_recurrence_rules, :event_id
    remove_column :events, :recurrence_period
    remove_column :events, :recurrence_basis
    remove_column :events, :recurrence_limit
    remove_column :events, :recurrence_count
    remove_column :events, :recurrence_interval
  end

  def self.down
    drop_table :event_recurrence_rules
    add_column :events, :recurrence_period, :string
    add_column :events, :recurrence_basis, :string
    add_column :events, :recurrence_limit, :datetime
    add_column :events, :recurrence_count, :integer
    add_column :events, :recurrence_interval, :integer
  end
end

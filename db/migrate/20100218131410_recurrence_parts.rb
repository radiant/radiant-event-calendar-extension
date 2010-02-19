class RecurrenceParts < ActiveRecord::Migration
  def self.up
    remove_column :events, :recurrence_rule
    add_column :events, :recurrence_period, :string
    add_column :events, :recurrence_basis, :string
    add_column :events, :recurrence_limit, :datetime
    add_column :events, :recurrence_count, :integer
  end

  def self.down
    remove_column :events, :recurrence_period
    remove_column :events, :recurrence_basis
    remove_column :events, :recurrence_limit
    remove_column :events, :recurrence_count
    add_column :events, :recurrence_rule, :string
  end
end

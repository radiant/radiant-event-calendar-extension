class Occurrences < ActiveRecord::Migration
  def self.up
    create_table :event_occurrences do |t|
      t.column :event_id, :integer
      t.column :calendar_id, :integer
      t.column :event_venue_id, :integer
      t.column :start_date, :datetime
      t.column :end_date, :datetime
      t.column :site_id, :integer
    end
    add_index :event_occurrences, [:event_id, :calendar_id]
  end

  def self.down
    drop_table :event_occurrences
  end
end

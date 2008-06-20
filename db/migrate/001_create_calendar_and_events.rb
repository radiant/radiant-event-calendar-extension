class CreateCalendarAndEvents < ActiveRecord::Migration
  def self.up
    create_table :calendars do |t|
      t.column :name, :string
      t.column :description, :text
    end
    create_table :events do |t|
      t.column :start_date, :datetime
      t.column :end_date, :datetime
      t.column :title, :string
      t.column :description, :text
      t.column :location, :string
      t.column :calendar_id, :integer
    end
  end

  def self.down
    drop_table :calendars
    drop_table :events
  end
end

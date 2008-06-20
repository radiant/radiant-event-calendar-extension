class CreateIcals < ActiveRecord::Migration
  def self.up
    create_table :icals do |t|
      t.column :calendar_id, :integer
      t.column :ical_url, :string
      t.column :last_refresh_count, :integer
      t.column :last_refresh_date, :datetime
    end
  end
  def self.down
    drop_table :icals
  end
end
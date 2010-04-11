class VenuesAndCategories < ActiveRecord::Migration
  def self.up
    create_table :event_venues do |t|
      t.column :title, :string
      t.column :address, :string
      t.column :url, :string
      t.column :description, :text
      t.column :postcode, :string
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :lock_version, :integer
      t.column :site_id, :integer
    end
    add_column :events, :event_venue_id, :integer
    add_index :events, :event_venue_id
  end

  def self.down
    drop_table :event_venues
  end
end

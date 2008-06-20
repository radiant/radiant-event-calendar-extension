class AddSlug < ActiveRecord::Migration
  def self.up
    add_column :calendars, :slug, :string
  end

  def self.down
    remove_column :calendars, :slug
  end
end

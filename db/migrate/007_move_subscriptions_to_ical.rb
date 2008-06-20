class MoveSubscriptionsToIcal < ActiveRecord::Migration

  def self.up
    Calendar.find(:all).each do |c|
      Ical.create(:ical_url=>c.ical_url, :last_refresh_date=>c.last_refresh_date, :last_refresh_count=>c.last_refresh_count, :calendar_id=>c.id)
    end
  end

  def self.down
    Ical.find(:all).each do |c|
      Calendar.create(:ical_url=>c.ical_url, :last_refresh_date=>c.last_refresh_date, :last_refresh_count=>c.last_refresh_count, :calendar_id=>c.id)
    end
  end

end
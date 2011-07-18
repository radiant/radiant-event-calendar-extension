Radiant.config do |config|
  config.namespace('event_calendar') do |calendar|
    calendar.define 'path', :default => "/calendar", :allow_blank => false
    calendar.define 'icals_path', :default => "/icals", :allow_blank => false
    calendar.define 'cache_duration', :type => :integer, :default => 3600, :units => 'seconds'
    calendar.define 'refresh_interval', :type => :integer, :default => 3600, :units => 'seconds'
    calendar.define 'recurrence_horizon', :type => :integer, :default => 10, :units => 'years'
  end
end 

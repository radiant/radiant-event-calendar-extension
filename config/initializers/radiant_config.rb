Radiant.config do |config|
  config.namespace('event_calendar') do |forum|
    forum.define 'icals_path', :default => "/icals"
  end
end 

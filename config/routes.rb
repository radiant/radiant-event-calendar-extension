ActionController::Routing::Routes.draw do |map|
  map.namespace :admin, :path_prefix => '/admin/event_calendar' do |cal|
    cal.resources :calendars, :member => {:remove => :get}
    cal.resources :icals, :collection => {:refresh_all => :any}, :member => {:refresh => :put}
    cal.resources :events, :member => {:remove => :get}
    cal.resources :event_venues, :member => {:remove => :get}, :has_many => :events
    cal.calendars_home '/', :controller => 'events', :action => 'index'
  end
  
  calendar_prefix = Radiant.config['event_calendar.path'] || "/calendar"
  map.resources :events, :path_prefix => calendar_prefix, :only => [:index, :show]
  map.calendar "#{calendar_prefix}.:format", :controller => 'events', :action => 'index'
  map.calendar_year "#{calendar_prefix}/:year", :controller => 'events', :action => 'index'
  map.calendar_month "#{calendar_prefix}/:year/:month", :controller => 'events', :action => 'index'
  map.calendar_day "#{calendar_prefix}/:year/:month/:mday", :controller => 'events', :action => 'index'
end

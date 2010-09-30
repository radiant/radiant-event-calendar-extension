ActionController::Routing::Routes.draw do |map|
  map.namespace :admin, :path_prefix => '/admin/event_calendar' do |cal|
    cal.resources :calendars, :member => {:remove => :get}
    cal.resources :icals, :collection => {:refresh_all => :any}, :member => {:refresh => :put}
    cal.resources :events, :member => {:remove => :get}
    cal.resources :event_venues, :member => {:remove => :get}, :has_many => :events
    cal.calendars_home '/', :controller => 'events', :action => 'index'
  end
  map.calendar "/calendar.:format", :controller => 'events', :action => 'index'
  map.calendar_year "/calendar/:year", :controller => 'events', :action => 'index'
  map.calendar_month "/calendar/:year/:month", :controller => 'events', :action => 'index'
  map.calendar_day "/calendar/:year/:month/:mday", :controller => 'events', :action => 'index'
end

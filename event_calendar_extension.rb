class EventCalendarExtension < Radiant::Extension
  version "0.91"
  description "An event calendar extension that administers events locally or draws them from any ical or CalDAV publishers (Google Calendar, .Mac, Darwin Calendar Server, etc.)"
  url "http://radiant.spanner.org/event_calendar"

  EXT_ROOT = '/admin/event_calendar'

  define_routes do |map|
    map.namespace :admin, :path_prefix => EXT_ROOT do |cal|
      cal.resources :calendars
      cal.resources :icals, :collection => {:refresh_all => :any}, :member => {:refresh => :put}
      cal.resources :events, :member => {:remove => :get}
      cal.resources :event_venues, :member => {:remove => :get}
      cal.calendars_home '/', :controller => 'events', :action => 'index'
    end
    map.calendar "/calendar.:format", :controller => 'events', :action => 'index'
    map.calendar_year "/calendar/:year", :controller => 'events', :action => 'index'
    map.calendar_month "/calendar/:year/:month", :controller => 'events', :action => 'index'
    map.calendar_day "/calendar/:year/:month/:mday", :controller => 'events', :action => 'index'
  end
  
  extension_config do |config|
    config.gem 'ri_cal', :source => 'http://gemcutter.org'
    config.gem 'chronic', :source => 'http://gemcutter.org'
    config.gem 'uuidtools', :source => 'http://gemcutter.org'
    config.gem 'will_paginate', :source => 'http://gemcutter.org'
  end
  
  def activate
    Page.send :include, EventCalendarTags                                   # defines a wide range of events: tags for use on normal and calendar pages
    Status.send :include, EventStatuses                                     # adds support for draft and submitted events
    UserActionObserver.instance.send :add_observer!, Calendar               # adds ownership and update hooks to the calendar data
    UserActionObserver.instance.send :add_observer!, Event                  # adds ownership and update hooks to the event data
    
    if Radiant::Config.table_exists? && !Radiant::Config["event_calendar.icals_path"]
      Radiant::Config["event_calendar.icals_path"] = "icals"
    end

    unless defined? admin.calendar
      Radiant::AdminUI.send :include, EventCalendarAdminUI
      admin.calendar = Radiant::AdminUI.load_default_calendar_regions
      admin.event = Radiant::AdminUI.load_default_event_regions
      admin.event_venue = Radiant::AdminUI.load_default_event_venue_regions
    end
    
    if respond_to?(:tab)
      tab("Content") do
        add_item("Calendar", EXT_ROOT)
      end
    else
      admin.tabs.add "Calendar", EXT_ROOT, :after => "Snippets", :visibility => [:all]
    end

  end
end

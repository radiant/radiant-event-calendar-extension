class EventCalendarExtension < Radiant::Extension
  version "0.90"
  description "An event calendar extension that administers events locally or draws them from any ical or CalDAV publishers (Google Calendar, .Mac, Darwin Calendar Server, etc.)"
  url "http://radiant.spanner.org/event_calendar"

  EXT_ROOT = '/admin/event_calendar'

  define_routes do |map|
    map.namespace :admin, :path_prefix => EXT_ROOT do |cal|
      cal.resources :calendars
      cal.resources :icals, :collection => {:refresh_all => :any}, :member => {:refresh => :put}
      cal.resources :events, :member => {:remove => :post}
      cal.resources :event_venues, :member => {:remove => :post}
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
    CalendarPeriod                                                          # defines the window in time that we want to display
    EventCalendarPage                                                       # the main calendar viewer: takes period, chooses events, shows page
    Radiant::LinkRenderer                                                   # removes all the viewhelper calls from the pagination so that it works in a model
    Status.send :include, EventStatuses                                     # adds support for draft and submitted events
    Page.send :include, EventCalendarTags                                   # defines a wide range of events: tags for use on normal and calendar pages
    UserActionObserver.instance.send :add_observer!, Calendar               # adds ownership and update hooks to the calendar data
    EventsController.send :include, ResourcePagination
    Admin::ResourceController.send :include, ResourcePagination
    
    
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
        add_item("Events", EXT_ROOT)
        add_item("Calendars", EXT_ROOT + '/calendars')
      end
    else
      admin.tabs.add "Calendar", EXT_ROOT, :after => "Snippets", :visibility => [:all]
    end

  end
end

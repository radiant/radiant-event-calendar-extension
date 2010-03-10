class EventCalendarExtension < Radiant::Extension
  version "0.82"
  description "An event calendar extension which draws events from any ical or CalDAV publishers (Google Calendar, .Mac, Darwin Calendar Server, etc.)"
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
  end
  
  extension_config do |config|
    config.gem 'ri_cal', :source => 'http://gemcutter.org'
    config.gem 'chronic', :source => 'http://gemcutter.org'
    config.gem 'uuidtools', :source => 'http://gemcutter.org'
    config.gem 'will_paginate', :source => 'http://gemcutter.org'
  end
  
  def activate
    CalendarPeriod                                                          # a handy way of describing the window in time that we want to display
    EventCalendarPage                                                       # the main calendar viewer: takes period, chooses events, shows page
    PaginationLinkRenderer                                                  # removes all the viewhelper calls from the pagination so that it works in a model
    Status.send :include, EventStatuses                                     # adds support for draft and submitted events
    ApplicationController.send :include, ApplicationControllerExtensions    # adds exclude_stylesheet and exclude_javascript
    Page.send :include, EventCalendarTags                                   # defines a wide range of events: tags for use on normal and calendar pages
    UserActionObserver.instance.send :add_observer!, Calendar               # adds ownership and update hooks to the calendar data
    
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
      if admin.tabs["Calendar"].respond_to?(:add_link)   # that is, if the submenu extension is installed
        admin.tabs["Calendar"].add_link "events", EXT_ROOT
        admin.tabs["Calendar"].add_link "calendars", EXT_ROOT + "/calendars"
        admin.tabs["Calendar"].add_link "places", EXT_ROOT + "/event_venues"
        admin.tabs["Calendar"].add_link "refresh subscriptions", EXT_ROOT + "/icals/refresh_all"
      end
    end

  end
end

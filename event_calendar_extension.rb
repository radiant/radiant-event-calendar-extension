class EventCalendarExtension < Radiant::Extension
  version "0.8"
  description "An event calendar extension which draws events from any ical or CalDAV publishers (Google Calendar, .Mac, Darwin Calendar Server, etc.)"
  url "http://radiant.spanner.org/event_calendar"

  EXT_ROOT = '/admin/event_calendar'

  define_routes do |map|
    map.namespace :admin, :path_prefix => EXT_ROOT do |cal|
      cal.resources :calendars
      cal.resources :icals, :collection => {:refresh_all => :any}, :member => {:refresh => :put}
      cal.resources :events
    end
  end
  
  extension_config do |config|
    config.gem 'vpim'
  end
  
  def activate
    CalendarPeriod
    EventCalendarPage
    ApplicationHelper.send :include, Admin::CalendarHelper
    Page.send :include, EventCalendarTags
    UserActionObserver.instance.send :add_observer!, Calendar
    
    if Radiant::Config.table_exists? && !Radiant::Config["event_calendar.icals_path"]
      Radiant::Config["event_calendar.icals_path"] = "icals"
    end

    unless defined? admin.calendar
      Radiant::AdminUI.send :include, EventCalendarAdminUI
      admin.calendar = Radiant::AdminUI.load_default_calendar_regions
    end
    
    admin.tabs.add "Calendars", EXT_ROOT + "/calendars", :after => "Snippets", :visibility => [:all]
    if admin.tabs["Calendars"].respond_to?(:add_link)   # that is, if the submenu extension is installed
      admin.tabs["Calendars"].add_link "calendar list", EXT_ROOT + "/calendars"
      admin.tabs["Calendars"].add_link "new subscription", EXT_ROOT + "/calendars/new"
      admin.tabs["Calendars"].add_link "refresh all", EXT_ROOT + "/icals/refresh_all"
    end
  end
end

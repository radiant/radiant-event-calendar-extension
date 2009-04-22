class EventCalendarExtension < Radiant::Extension
  version "0.8"
  description "An event calendar extension which draws events from any ical publishers (Google Calendar, .Mac, etc.)"
  url "http://www.hellovenado.com"

  EXT_ROOT = '/admin/event_calendar'

  define_routes do |map|
    map.with_options :path_prefix => EXT_ROOT do |ext|
      ext.resources :calendars, :collection => {:help => :get}
      ext.resources :icals, :collection => {:refresh_all => :put}, :member => {:refresh => :put}
      ext.resources :events
    end
  end
  
  def activate
    CalendarPeriod
    EventCalendarPage
    ApplicationHelper.send :include, CalendarHelper
    Page.send :include, EventCalendarTags
    
    admin.tabs.add "Calendars", EXT_ROOT + "/calendars", :after => "Snippets", :visibility => [:all]
    if Radiant::Config.table_exists? && !Radiant::Config["event_calendar.icals_path"]
      Radiant::Config["event_calendar.icals_path"] = "icals"
    end

  end
end

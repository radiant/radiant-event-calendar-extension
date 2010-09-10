class EventCalendarExtension < Radiant::Extension
  version "1.0.0"
  description "An event calendar extension that administers events locally or draws them from any ical or CalDAV publishers (Google Calendar, .Mac, Darwin Calendar Server, etc.)"
  url "http://radiant.spanner.org/event_calendar"

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
        add_item("Calendar", '/admin/event_calendar')
      end
    else
      admin.tabs.add "Calendar", '/admin/event_calendar', :after => "Snippets", :visibility => [:all]
    end

  end
end

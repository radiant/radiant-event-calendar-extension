# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

require "radiant-event_calendar-extension"

class EventCalendarExtension < Radiant::Extension
  version RadiantEventCalendarExtension::VERSION
  description RadiantEventCalendarExtension::DESCRIPTION
  url RadiantEventCalendarExtension::URL

  extension_config do |config|
    config.gem "ri_cal"
    config.gem "chronic"
    config.gem "uuidtools"
  end

  def activate
    Page.send :include, EventCalendarTags                                   # defines a wide range of events: tags for use on normal and calendar pages
    Status.send :include, EventStatuses                                     # adds support for draft and submitted events
    UserActionObserver.instance.send :add_observer!, Calendar               # adds ownership and update hooks to the calendar data
    UserActionObserver.instance.send :add_observer!, Event                  # adds ownership and update hooks to the event data
    Radiant::AdminUI.send :include, EventCalendarAdminUI                    # defines shards for further extension of the calendar admin pages

    admin.calendar = Radiant::AdminUI.load_default_calendar_regions
    admin.event = Radiant::AdminUI.load_default_event_regions
    admin.event_venue = Radiant::AdminUI.load_default_event_venue_regions
    admin.dashboard.index.add :main, "coming_events" if admin.respond_to? :dashboard
    
    tab('calendar') do
      add_item('events', '/admin/event_calendar')
      add_item('calendars', '/admin/event_calendar/calendars')
      add_item('locations', '/admin/event_calendar/event_venues')
    end

  end
end

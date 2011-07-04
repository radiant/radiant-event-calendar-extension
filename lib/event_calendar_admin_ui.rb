module EventCalendarAdminUI

 def self.included(base)
   base.class_eval do

      attr_accessor :calendar, :event, :event_venue
      alias_method :calendars, :calendar
      alias_method :events, :event
      alias_method :event_venues, :event_venue

      def load_default_regions_with_event_calendar
        load_default_regions_without_event_calendar
        @calendar = load_default_calendar_regions
        @event = load_default_event_regions
        @event_venue = load_default_event_venue_regions
      end

      alias_method_chain :load_default_regions, :event_calendar

    protected

      def load_default_calendar_regions
        OpenStruct.new.tap do |calendar|
          calendar.edit = Radiant::AdminUI::RegionSet.new do |edit|
            edit.main.concat %w{edit_header edit_form}
            edit.form.concat %w{edit_name edit_ical edit_filing edit_description}
            edit.form_bottom.concat %w{edit_metadata edit_timestamp edit_buttons}
          end
          calendar.index = Radiant::AdminUI::RegionSet.new do |index|
            index.thead.concat %w{name_header url_header refresh_header action_header}
            index.tbody.concat %w{name_cell url_cell refresh_cell action_cell}
            index.bottom.concat %w{buttons}
          end
          calendar.remove = calendar.index
          calendar.new = calendar.edit
        end
      end

      def load_default_event_regions
        OpenStruct.new.tap do |event|
          event.edit = Radiant::AdminUI::RegionSet.new do |edit|
            edit.main.concat %w{edit_header edit_form}
            edit.form.concat %w{edit_event edit_date edit_description}
            edit.form_bottom.concat %w{edit_metadata edit_venue edit_timestamp edit_buttons}
          end
          event.index = Radiant::AdminUI::RegionSet.new do |index|
            index.top.concat %w{help_text}
            index.thead.concat %w{date_header title_header calendar_header time_header location_header modify_header}
            index.tbody.concat %w{date_cell title_cell calendar_cell time_cell location_cell modify_cell}
            index.bottom.concat %w{buttons}
          end
          event.remove = event.index
          event.new = event.edit
        end
      end

      def load_default_event_venue_regions
        OpenStruct.new.tap do |event_venue|
          event_venue.edit = Radiant::AdminUI::RegionSet.new do |edit|
            edit.main.concat %w{edit_header edit_form}
            edit.form.concat %w{edit_event_venue}
            edit.form_bottom.concat %w{edit_timestamp edit_buttons}
          end
          event_venue.index = Radiant::AdminUI::RegionSet.new do |index|
            index.top.concat %w{help_text}
            index.thead.concat %w{title_header location_header url_header modify_header}
            index.tbody.concat %w{title_cell location_cell url_cell modify_cell}
            index.bottom.concat %w{buttons}
          end
          event_venue.remove = event_venue.index
          event_venue.new = event_venue.edit
        end
      end

    end
  end
end


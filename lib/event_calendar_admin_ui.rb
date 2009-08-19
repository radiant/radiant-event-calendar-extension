module EventCalendarAdminUI

 def self.included(base)
   base.class_eval do

      attr_accessor :calendar
      alias_method :calendars, :calendar

      def load_default_regions_with_calendar
        load_default_regions_without_calendar
        @calendar = load_default_calendar_regions
      end

      alias_method_chain :load_default_regions, :calendar

      protected

        def load_default_calendar_regions
          returning OpenStruct.new do |calendar|
            calendar.edit = Radiant::AdminUI::RegionSet.new do |edit|
              edit.main.concat %w{edit_header edit_form}
              edit.form.concat %w{edit_name edit_url edit_description edit_ical}
              edit.form_bottom.concat %w{edit_timestamp edit_buttons}
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
      
    end
  end
end


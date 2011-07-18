class CalendarEventsDataset < Dataset::Base  
  uses :calendars
  
  def load
    create_calendar :local do
      create_event 'simple', :title => "Simple Event", :start_date => "2009-11-03 18:30:00"
      create_event 'repeating', :title => 'Repeating Event', :start_date => "2009-11-03 18:30:00", :end_date => "2009-11-03 20:00:00" do
        add_recurrence :period => "weekly", :interval => "1", :basis => 'count', :limiting_count => "4"
      end
      create_event 'spanning', :title => "Simple Event", :start_date => "2009-11-03 09:00:00", :end_date => "2009-11-04 17:00:00"
      create_event 'allday', :title => "All Day Event", :start_date => "2009-11-03 09:00:00", :end_date => "2009-11-04 17:00:00", :all_day => true
      create_event 'facebooked', :title => "Facebook Event", :start_date => "2009-11-03 09:00:00", :end_date => "2009-11-04 17:00:00", :facebook_id => "101"
    end
  end

  helpers do
    def create_event(title, attributes={})
      attributes = event_attributes(attributes.update(:title => title))
      event = create_model Event, title.symbolize, attributes
      if block_given?
        @event = event
        yield
      end
      event
    end
  end
  
  def event_attributes(attributes={})
    title = attributes[:title] || "Default"
    symbol = title.symbolize
    attributes = {
      :calendar => @calendar,
      :title => title,
      :description => 'An event'
    }.merge(attributes)
    attributes[:site] = sites(:test) if defined? Site
    attributes
  end
  
  def add_recurrence(attributes={})
    @event.recurrence_rules.create(attributes)
  end
  
end

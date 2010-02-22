require File.dirname(__FILE__) + '/../spec_helper'

describe Ical do
  dataset :calendars
  
  before do
    @ical = calendars(:dummy).ical
  end
      
  describe "reading an ics file with GMT times" do
    before do
      lambda {@ical.parse_file(File.dirname(__FILE__) + "/../files/dummy.ics")}.should_not raise_error
    end

    it "should import events" do
      @ical.calendar.events.should_not be_empty
      @ical.calendar.events.first.title.should == "Test Event"
      @ical.calendar.events.last.title.should == "All Day"
    end
    
    it "should record timed events (with GMT times)" do
      @ical.calendar.events.first.start_date.should == DateTime.civil(2009, 2, 24, 9, 0, 0)
      @ical.calendar.events.first.all_day?.should be_false
    end

    it "should record all-day events (with GMT times set to midnight)" do
      @ical.calendar.events.last.start_date.should == DateTime.civil(2009, 2, 24)
      @ical.calendar.events.last.end_date.should == DateTime.civil(2009, 2, 24)
      @ical.calendar.events.last.all_day?.should be_true
    end

    it "should record repeating events" do
      event = @ical.calendar.events.find_by_title("Repeating Event")
      event.recurrence_rules.should_not be_empty
      rrule = event.recurrence_rules.first
      rrule.period.downcase.should == 'daily'
      rrule.interval.should == 1
      rrule.limiting_date.should == DateTime.civil(2009, 2, 28, 4, 59, 59)
    end

  end
  describe "reading an ics file from another timezone" do
    before do
      lambda {@ical.parse_file(File.dirname(__FILE__) + "/../files/ny.ics")}.should_not raise_error
    end
    
    it "should import events" do
      @ical.calendar.events.should_not be_empty
      @ical.calendar.events.first.title.should == "Test Event"
    end
    
    it "should record events (with adjusted GMT times)" do
      @ical.calendar.events.first.start_date.should == DateTime.civil(2009, 2, 24, 14, 0, 0)
    end
    
  end
  
  

end


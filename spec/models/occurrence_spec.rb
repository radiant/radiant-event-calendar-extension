require File.dirname(__FILE__) + '/../spec_helper'

describe EventOccurrence do
  dataset :calendar_events

  describe "A solitary occurrence" do
    before do 
      @event = events(:simple)
      @event.send :write_occurrences
      @occurrence = @event.occurrences.first
    end
    
    it "should have the same dates as its event" do
      @occurrence.start_date.should == @event.start_date
      @occurrence.end_date.should == @event.end_date
    end
  end
  
  describe "A recurrence" do
    before do 
      @event = events(:repeating)
      @event.send :write_occurrences
      @occurrence = @event.occurrences.last
    end
    
    it "should have its own start and end dates" do
      @occurrence.start_date.should_not == @event.start_date
      @occurrence.end_date.should_not == @event.end_date
    end
    
    it "should have the right event" do
      @occurrence.event.should == @event
    end

    it "should have the right calendar" do
      @occurrence.calendar.should == calendars(:local)
    end

    [:title, :description, :location, :postcode, :url, :keywords, :contact].each do |field|
      it "should return the same #{field} as its event" do
        @occurrence.send(field).should == @event.send(field)
      end
    end
  end
end

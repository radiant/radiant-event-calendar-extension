require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  dataset :calendar_events
  
  before do
    @ical = calendars(:dummy).ical
    @ical.parse_file(File.dirname(__FILE__) + "/../files/dummy.ics")
  end
      
  describe "A simple event" do
    before do 
      @event = events(:simple)
    end
    
    it "should be valid" do
      @event.valid?.should be_true
    end
    
    [:uuid, :title, :start_date, :status_id].each do |field|
      it "should not be valid without a #{field}" do
        @event.send "#{field}=".intern, nil
        @event.valid?.should be_false
      end
    end
    
    it "should have a default end date" do
      @event.end_date.should_not be_nil
      @event.duration.should == 1.hour
    end
  end

  describe "A spanning event" do
    before do 
      @event = events(:spanning)
    end
    
    it "should have the right duration" do
      @event.duration.should == 32.hours
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
  end

  describe "A repeating event" do
    before do 
      @event = events(:repeating)
      @event.send :update_occurrences
    end
    
    it "should have the right duration" do
      @event.duration.should == 90.minutes
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
    
    it "should have a recurrence rule" do
      @event.recurrence_rules.should_not be_empty
      @event.recurrence_rules.first.period.should == 'weekly'
      @event.recurrence_rules.first.interval.should == 1
      @event.recurrence_rules.first.limiting_count.should == 4
    end
    
    it "should have occurrences" do
      @event.occurrences.should_not be_empty
    end
    
    describe "recurring" do
      before do 
        @occurrence = @event.occurrences.last
      end
      
      it "should have the right master" do
        @occurrence.master.should == @event
      end
      
      it "should resemble its master in most ways" do
        [:title, :description, :event_venue, :keywords, :url, :postcode, :duration].each do |att|
          @occurrence.send(att).should == @event.send(att)
        end
      end
      
      it "should have a different date and uuid" do
        [:start_date, :end_date, :uuid].each do |att|
          @occurrence.send(att).should_not == @event.send(att)
        end
      end

    end
    
  end

end


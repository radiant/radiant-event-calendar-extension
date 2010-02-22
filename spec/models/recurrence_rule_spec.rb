require File.dirname(__FILE__) + '/../spec_helper'

describe EventRecurrenceRule do
  dataset :recurrence
  
  describe "date-limited rule" do
    before do 
      @rule = event_recurrence_rules(:date_limited)
    end
    
    it "should be bounded" do
      @rule.unbounded?.should be_false
    end

    it "should report the right basis" do
      @rule.basis.should == 'limit'
    end

    it "should describe itself correctly" do
      @rule.to_s.should == "weekly until 24 February 2009"
    end
  end

  describe "count-limited rule" do
    before do 
      @rule = event_recurrence_rules(:count_limited)
    end
    
    it "should be bounded" do
      @rule.unbounded?.should be_false
    end

    it "should report the right basis" do
      @rule.basis.should == 'count'
    end

    it "should describe itself correctly" do
      @rule.to_s.should == "every 2 months, 12 times"
    end
  end

  describe "unlimited rule" do
    before do 
      @rule = event_recurrence_rules(:unlimited)
    end
    
    it "should not be bounded" do
      @rule.unbounded?.should be_true
    end

    it "should report no basis" do
      @rule.basis.should be_nil
    end
    
    it "should describe itself correctly" do
      @rule.to_s.should == "every 2 days, indefinitely"
    end
  end

  describe "imported rule" do
    before do 
      @rule = EventRecurrenceRule.from("FREQ=DAILY;INTERVAL=1;UNTIL=20090228")
    end
    
    it "should be bounded" do
      @rule.unbounded?.should be_false
    end

    it "should report the right basis" do
      @rule.basis.should == 'limit'
    end

    it "should have the right limiting date" do
      @rule.limiting_date.should == DateTime.civil(2009, 2, 28)
    end
    
    it "should describe itself correctly" do
      @rule.to_s.should == "daily until 28 February 2009"
    end
  end

end

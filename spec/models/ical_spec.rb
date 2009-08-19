require File.dirname(__FILE__) + '/../spec_helper'

describe Ical do
  dataset :calendars
  
  it "should be ok" do
    Ical.should_not be_nil
  end
  

end

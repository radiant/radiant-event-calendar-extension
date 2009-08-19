require File.dirname(__FILE__) + '/../spec_helper'

describe Calendar do
  dataset :calendars
  
  it "should be ok" do
    Calendar.should_not be_nil
  end
  

end

require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  dataset :calendars
  
  it "should be ok" do
    Event.should_not be_nil
  end
  

end

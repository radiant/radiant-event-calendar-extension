require File.dirname(__FILE__) + '/../spec_helper'

describe EventCalendarPage do
  dataset :calendar_pages
  
  it "should be a page" do
    pages(:calendar).is_a?(Page).should be_true
  end
  
  it "should be cacheable" do
    pages(:calendar).cache?.should be_true
  end
  
  describe ".find_by_url" do
    it "should return self to our own url" do
      pages(:calendar).find_by_url("/#{pages(:calendar).slug}/").should == pages(:calendar)
    end
  
    it "should return self to any child url" do
      pages(:calendar).find_by_url("/#{pages(:calendar).slug}/something").should == pages(:calendar)
    end
  end

end

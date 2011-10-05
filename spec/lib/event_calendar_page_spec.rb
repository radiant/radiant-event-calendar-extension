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
    it "should return self to our own path" do
      pages(:calendar).find_by_path("/#{pages(:calendar).slug}/").should == pages(:calendar)
    end
  
    it "should return self to any child path" do
      pages(:calendar).find_by_path("/#{pages(:calendar).slug}/something").should == pages(:calendar)
    end
  end

end

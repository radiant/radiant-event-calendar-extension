class CalendarPagesDataset < Dataset::Base
  uses :calendars, :home_page
  
  def load
    create_page "calendar", :slug => "calendar", :class_name => 'EventCalendarPage', :body => '<r:month />'
  end
 
end
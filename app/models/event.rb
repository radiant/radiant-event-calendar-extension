class Event < ActiveRecord::Base
  belongs_to :calendar
  
  def allday
    if start_date.hour == 0 && end_date.hour == 0 then
      return true
    end  
    return false
  end
end

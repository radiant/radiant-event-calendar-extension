class Event < ActiveRecord::Base
  belongs_to :calendar

  named_scope :within, lambda { |period| # seconds
    start = Time.now
    finish = start + period
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :between, lambda { |start, finish| # datetime objects
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :in_month, lambda { |year, month| # just numbers
    start = DateTime.new(year, month, 1)
    finish = start + 1.month
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }
  
  named_scope :on_day, lambda { |year, month, day| # just numbers
    start = DateTime.new(year, month, day)
    finish = start + 1.day
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }
  
  def allday
    if start_date.hour == 0 && end_date.hour == 0 then
      return true
    end  
    return false
  end
end

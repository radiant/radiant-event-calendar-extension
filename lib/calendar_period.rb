class CalendarPeriod
  include ActionView::Helpers::DateHelper
  
  attr_accessor :start, :duration
  
  def initialize(from=nil, length=nil)
    @start = from ? from.to_date : Date.today.beginning_of_month
    @duration = length || 1.month
  end
  
  def self.between(from,to)
    period = self.new(from)
    period.finish = to
    period
  end

  def finish
    start + duration
  end
  
  def finish=(datetime)
    duration = datetime - start
  end
  
  def to_s
    "#{distance_of_time_in_words(start, finish)} from #{start}"
  end
  
  def inspect
    %{#{start} to #{finish}}
  end
  
  # to expand the period to full calendar months
  # @period.pad
  
  def pad
    start = start.beginning_of_month
    finish = finish.end_of_month
  end

  # to shift the period forward one month
  # @period += 1.month

  def +(s)
    CalendarPeriod.new(start + s, duration)
  end
  
  # to shift the period back one month
  # @period -= 1.month
  
  def -(s)
    CalendarPeriod.new(start - s, duration)
  end
  
  # to extend the period by one month
  # @period << 1.month 
  
  def <<(s)
    @duration += s
  end
  
end

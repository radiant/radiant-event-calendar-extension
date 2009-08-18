class CalendarPeriod
  attr_accessor :begin_date, :end_date, :name, :amount, :end_set
  
  def initialize(from=nil, to=nil)
    @begin_date = from ? from.to_date : first_day_of_month
    if to
      @end_date = to.to_date
      @end_set = true
    else
      @end_set = false
      @name = "month"
      @amount = 1
    end
  end    

  def to_s
    @name
  end
  
  def inspect
    self.calculate_dates!
    %{#{@begin_date} to #{@end_date}}
  end
  
  def begin_date
    self.calculate_dates!
    @begin_date
  end
  
  def end_date
    self.calculate_dates!
    @end_date
  end
    
  def end_date=(date)
    @end_set = true
    @end_date = date
  end
  
  def calculate_dates!
    return if @end_set && @end_date
    case @name
      when "day"
        @end_date = @begin_date + (1 * @amount)
      when "week"
        @end_date = @begin_date + (7 * @amount)
      when "month"
        @end_date = @begin_date >> (1 * @amount)
      when "year"
        @end_date = @begin_date >> (12 * @amount)
    end
  end
  
  def first_day_of_month(date=Date.today)
    date.beginning_of_month
  end
  
  def last_day_of_month(date=Date.today)
    date.end_of_month
  end
  
end

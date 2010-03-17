class CalendarPeriod
  include ActionView::Helpers::DateHelper
  
  attr_writer :start, :finish
    
  def self.between(from=nil,to=nil)
    raise StandardError, "CalendarPeriod.between requires either start or finish datetime" unless from || to
    period = self.new
    period.start = from
    period.finish = to
    period
  end
  
  def self.from(from, duration=nil)
    to = from + duration if duration
    between(from, to)
  end
  
  def self.to(to, duration=nil)
    from = to - duration if duration
    between(from, to)
  end
  
  def self.default
    between(Time.now, nil)
  end
  
  def default?
    finish.nil? && (Time.now - start).to_i.abs < 1.minute
  end
  
  def start
    @start.to_datetime if @start
  end

  def finish
    @finish.to_datetime if @finish
  end
  
  def duration
    if bounded?
      finish - start
    else
      'indefinite'
    end
  end
    
  def duration=(s)
    if start
      finish = start + s
    elsif finish
      start = finish - s
    end
  end
  
  def bounded?
    start && finish
  end
  
  def unbounded?
    !bounded?
  end
  
  # descriptions
  
  def to_s
    "#{distance_of_time_in_words(start, finish)} from #{start}"
  end
  
  def inspect
    detailed = "%-1I:%M%p %d/%m/%Y"
    %{#{describe_start(detailed)} to #{describe_finish(detailed)}}
  end
  
  [:day, :week, :month, :year].each do |period|
    define_method "is_#{period}?".intern do
      bounded? && start == start.send("beginning_of_#{period}".intern) && finish == start.send("end_of_#{period}".intern)
    end
  end
    
  def describe_start(date_format=nil)
    if start
      unless date_format
        date_format = "%d %B"
        date_format += " %Y" unless start.year == Time.now.year
      end
      start.to_datetime.strftime(date_format)
    end
  end

  def describe_finish(date_format=nil)
    if finish
      unless date_format
        date_format = "%d %B"
        date_format += " %Y" unless finish.year == Time.now.year
      end
      finish.to_datetime.strftime(date_format)
    end
  end
  
  def description
    return "on #{start.mday} #{monthname} #{start.year}" if is_day?
    return "in week #{start.cweek} of #{start.year}" if is_week?
    return "in #{monthname} #{start.year}" if is_month?
    return "in #{start.year}" if is_year?
    return "from #{describe_start} onwards" unless finish
    return "until #{describe_finish}" unless start
    "between #{describe_start} and #{describe_finish}"
  end
  
  def monthname
    i = start ? start.month : finish.month
    Date::MONTHNAMES[i]
  end
    
  # to expand the period to full calendar months
  # @period.pad!
  
  def pad!
    start = start.beginning_of_month if start
    finish = finish.end_of_month if finish
  end

  # to shift the period forward one month
  # @period += 1.month

  def +(s)
    start = start + s if start
    finish = finish + s if finish
  end
  
  # to shift the period back one month
  # @period -= 1.month
  
  def -(s)
    start = start - s if start
    finish = finish - s if finish
  end
  
  # to extend the period by one month
  # @period << 1.month
  
  def <<(s)
    if bounded?
      finish += s
    else
      duration = s
    end
  end
  
end

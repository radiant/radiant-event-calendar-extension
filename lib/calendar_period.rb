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
    I18n.t 'calendar_period.to_s',
           :distance_of_time_in_words => distance_of_time_in_words(start, finish),
           :start => (I18n.l start, :format => :default)
  end
  
  def inspect
    I18n.t 'calendar_period.inspect',
           :describe_start => describe_start(:calendar_period_describe_detailed),
           :describe_finish => describe_finish(:calendar_period_describe_detailed)
  end
  
  [:day, :week, :month, :year].each do |period|
    define_method "is_#{period}?".intern do
      bounded? && start == start.send("beginning_of_#{period}".intern) && finish == start.send("end_of_#{period}".intern)
    end
  end
    
  def describe_start(date_format=nil)
    if start
      unless date_format
        date_format = :calendar_period_describe
        date_format = :calendar_period_describe_with_year unless start.year == Time.now.year
      end
      I18n.l start, :format => date_format
    end
  end

  def describe_finish(date_format=nil)
    if finish
      unless date_format
        date_format = :calendar_period_describe
        date_format = :calendar_period_describe_with_year unless finish.year == Time.now.year
      end
      I18n.l finish, :format => date_format
    end
  end
  
  def description
    return I18n.t 'calendar_period.description_day',
             :day => I18n.l(start, :format => "%d"),
             :monthname => I18n.l(start ? start : finish, :format => "%B"),
             :year => I18n.l(start, :format => "%Y") if is_day?
    return I18n.l start, :format => :calendar_period_description_week if is_week?
    return I18n.l start, :format => :calendar_period_description_month if is_month?
    return I18n.l start, :format => :calendar_period_description_year if is_year?
    return I18n.t 'calendar_period.onwards', :describe_start => describe_start unless finish
    return I18n.t 'calendar_period.until', :describe_finish => describe_finish unless start
    I18n.t 'calendar_period.between', :describe_finish => describe_finish, :describe_start => describe_start
  end
  
  def monthname
    I18n.l(start ? start : finish, :format => "%B")
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

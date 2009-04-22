class EventSearch
  attr_accessor :category, :calendars, :slugs, :period

  def initialize
    Ical.check_refreshments
    @period = CalendarPeriod.new
    @slugs = ["all"]
  end

  def slugs=(new_slugs)
    unless new_slugs.blank?
      @slugs = new_slugs.split("|").collect { |s| s.downcase }
    end
  end

  def execute
    search = Event.between(@period.begin_date, @period.end_date)
    search = search.in_calendars(slugs) unless slugs == 'all' || slugs.nil?
    search.find(:all, :include => :calendar, :order => "start_date ASC")
  end

end
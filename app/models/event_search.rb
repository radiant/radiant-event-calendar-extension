class EventSearch
  attr_accessor :category, :calendars, :slugs, :period

  def initialize
    @period = Period.new
    @slugs = ["all"]
  end

  def slugs=(new_slugs)
    unless new_slugs.blank?
      @slugs = new_slugs.split("|").collect { |s| s.downcase }
    end
  end

  def execute
    if slugs.to_s == "all" or slugs.nil?
      events = Event.find(:all, :conditions => ["start_date BETWEEN ? AND ?", @period.begin_date, @period.end_date], :include => :calendar, :order => "start_date ASC")
    else
      events = Event.find(:all, :conditions => ["start_date BETWEEN ? AND ? AND slug IN(?)", @period.begin_date, @period.end_date, slugs], :include => :calendar, :order => "start_date ASC")
    end
    events.find_all { |e| e.calendar.category == @category } unless @category.nil?
    return events
  end

  class Period
    attr_accessor :begin_date, :end_date, :name, :amount
    
    def initialize
      @begin_date = Date.today
      @end_date = @begin_date >> 1
      @name = "month"
      @amount = 1
      self.calculate_dates!
    end    

    def to_s
      @name
    end
    
    def begin_date=(new_begin_date)
      unless new_begin_date.blank?
        @begin_date = new_begin_date.to_date
        self.calculate_dates!
      end
    end

    def end_date=(new_end_date)
      unless new_end_date.blank?
        @end_date = new_end_date.to_date
        @name = nil
      end
    end

    def name=(new_name)
      @name = new_name
      self.calculate_dates!
    end
    
    def amount=(new_amount)
      unless new_amount.blank? || new_amount == 0
        @amount = new_amount
        self.calculate_dates!
      end
    end

    def calculate_dates!
      case @name
        when nil
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
  end

end
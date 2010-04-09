class EventOccurrence < ActiveRecord::Base
  
  belongs_to :event
  belongs_to :calendar          # for efficient retrieval
  belongs_to :event_venue       # we can just grab occurrences
  
  has_site if respond_to? :has_site

  delegate :title, :description, :location, :postcode, :url, :keywords, :contact, :all_day, :one_day?, :within_day?, :to => :event

  before_validation_on_create :set_defaults
  
  named_scope :imported, { :conditions => ["status_id = ?", Status[:imported].to_s] }
  named_scope :submitted, { :conditions => ["status_id = ?", Status[:submitted].to_s] }
  named_scope :approved, { :conditions => ["status_id >= (?)", Status[:published].to_s] }
  
  named_scope :in_calendars, lambda { |calendars| # list of calendar objects
    ids = calendars.map{ |c| c.id }
    { :conditions => [ ids.map{"calendar_id = ?"}.join(" OR "), *ids] }
  }
  
  named_scope :after, lambda { |datetime| # datetime. eg calendar.occurrences.after(Time.now)
    { :conditions => ['start_date > ?', datetime] }
  }
  
  named_scope :before, lambda { |datetime| # datetime. eg calendar.occurrences.before(Time.now)
    { :conditions => ['start_date < ?', datetime] }
  }
  
  named_scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
    { :conditions => ['(start_date < :finish AND end_date > :start) OR (end_date IS NULL AND start_date < :finish AND start_date > :start)', {:start => start, :finish => finish}] }
  }

  named_scope :within, lambda { |period| # seconds. eg calendar.occurrences.within(6.months)
    start = Time.now
    finish = start + period
    between(start, finish)
  }

  named_scope :in_the_last, lambda { |period| # seconds. eg calendar.occurrences.in_the_last(1.week)
    finish = Time.now
    start = finish - period
    between(start, finish)
  }

  named_scope :in_year, lambda { |year| # just a number. eg calendar.occurrences.in_year(2010)
    start = DateTime.civil(year)
    finish = start + 1.year
    between(start, finish)
  }

  named_scope :in_month, lambda { |year, month| # numbers. eg calendar.occurrences.in_month(2010, 12)
    start = DateTime.civil(year, month)
    finish = start + 1.month
    between(start, finish)
  }
  
  named_scope :in_week, lambda { |year, week| # numbers, with a commercial week: eg calendar.occurrences.in_week(2010, 35)
    start = DateTime.commercial(year, week)
    finish = start + 1.week
    between(start, finish)
  }
  
  named_scope :on_day, lambda { |year, month, day| # numbers: eg calendar.occurrences.on_day(2010, 12, 12)
    start = DateTime.civil(year, month, day)
    finish = start + 1.day
    between(start, finish)
  }

  def status
    Status.find(self.status_id)
  end

  def status=(value)
    self.status_id = value.id
  end

protected

  # the default occurrence just echoes the event
  # recurrences will override at least start_date.

  def set_defaults
    [:start_date, :end_date, :calendar_id, :event_venue_id, :status_id].each do |col|
      self[col] ||= event.send(col)
    end
  end

end

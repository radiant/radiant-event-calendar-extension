require 'uuidtools'

class Event < ActiveRecord::Base
  attr_accessor :start_time, :end_time, :recurrence_period, :recurrence_basis, :recurrence_limit, :recurrence_count
  
  belongs_to :calendar
  is_site_scoped if respond_to? :is_site_scoped
  
  before_validation_on_create :get_uuid
  validates_presence_of :uuid, :title, :start_date, :status_id
  validates_uniqueness_of :uuid

  named_scope :imported, { :conditions => ["status_id = ?", Status[:imported].to_s] }
  named_scope :submitted, { :conditions => ["status_id = ?", Status[:submitted].to_s] }
  named_scope :approved, { :conditions => ["status_id >= (?)", Status[:published].to_s] }

  named_scope :in_calendars, lambda { |calendars| # list of calendar objects
    ids = calendars.map{ |c| c.id }
    { :conditions => [ ids.map{"calendar_id = ?"}.join(" OR "), *ids] }
  }
  
  named_scope :after, lambda { |datetime| # datetime. eg calendar.events.after(Time.now)
    { :conditions => ['start_date > ?', datetime] }
  }
  
  named_scope :before, lambda { |datetime| # datetime. eg calendar.events.before(Time.now)
    { :conditions => ['start_date < ?', datetime] }
  }
  
  named_scope :within, lambda { |period| # seconds. eg calendar.events.within(6.months)
    start = Time.now
    finish = start + period
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :in_the_last, lambda { |period| # seconds. eg calendar.events.in_the_last(1.week)
    finish = Time.now
    start = finish - period
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :in_year, lambda { |year| # just a number. eg calendar.events.in_year(2010)
    start = DateTime.civil(year, 1, 1)
    finish = start + 1.year
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }

  named_scope :in_month, lambda { |year, month| # numbers. eg calendar.events.in_month(2010, 12)
    start = DateTime.civil(year, month, 1)
    finish = start + 1.month
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }
  
  named_scope :in_week, lambda { |year, week| # numbers, with a commercial week: eg calendar.events.in_week(2010, 35)
    start = DateTime.commercial(year, week, 1)
    finish = start + 1.week
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }
  
  named_scope :on_day, lambda { |year, month, day| # numbers: eg calendar.events.on_day(2010, 12, 12)
    start = DateTime.civil(year, month, day)
    finish = start + 1.day
    { :conditions => ['start_date BETWEEN ? AND ?', start, finish] }
  }
  
  def allday?
    start_date.hour == 0 && end_date.hour == 0
  end
  
  def nice_date
    start_date.to_datetime.strftime("%d %M %Y")
  end
  
  def nice_start_time
    if start_date.min == 0
      start_date.to_datetime.strftime("%-1I%p").downcase
    else
      start_date.to_datetime.strftime("%-1I:%M%p").downcase
    end
  end
  
  def editable?
    status != Status[:imported]
  end
  
  def status
    Status.find(self.status_id)
  end
  def status=(value)
    self.status_id = value.id
  end
  
protected

  def get_uuid
    self.uuid ||= UUID.timestamp_create().to_s
  end

end

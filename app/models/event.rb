require 'uuidtools'
class Event < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
  belongs_to :calendar
  is_site_scoped if respond_to? :is_site_scoped
  
  validates_presence_of :uuid, :title, :start_date, :status_id
  validates_uniqueness_of :uuid

  before_validation_on_create :get_uuid
  before_validation_on_create :set_default_status

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
    
  def date
    start_date.to_datetime.strftime(date_format)
  end

  def short_date
    start_date.to_datetime.strftime(short_date_format)
  end
  
  def start_time
    start_date.to_datetime.strftime(start_date.min == 0 ? round_time_format : time_format).downcase
  end

  def end_time
    end_date.to_datetime.strftime(end_date.min == 0 ? round_time_format : time_format).downcase if end_date
  end

  def starts
    if all_day?
      "all day"
    else
      start_time
    end
  end
  
  def finishes
    if end_date
      if within_day?
        end_time
      elsif all_day?
        "on #{end_date.to_datetime.strftime(short_date_format)}"
      else
        "#{end_time} on #{end_date.to_datetime.strftime(short_date_format)}"
      end
    end
  end
    
  def one_day?
    all_day? && within_day?
  end
  
  def within_day?
    (!end_date || start_date.to_date.jd == end_date.to_date.jd)
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
  
  def recurrence
    rec = ""
    unless recurrence_period.blank?
      rec << recurrence_period.titlecase
      rec << " for #{period_units}" if recurrence_basis == 'count' && recurrence_count
      rec << " until #{recurrence_limit.to_datetime.strftime(date_format)}" if recurrence_basis == 'limit' && recurrence_limit
    end
    rec
  end
  
  def period_units
    return unless recurrence_period && recurrence_count
    name = recurrence_period.sub(/ly$/, '')
    name = "day" if name == 'dai'
    pluralize(recurrence_count, name)
  end
  
  # a comprehensible subset of the RFC 2445 recurrence rule
  def recurrence_rule
    if !recurrence_period.blank? && recurrence_period != 'never'
      rule = ["FREQ=#{recurrence_period.upcase}"]
      rule << "COUNT=#{recurrence_count}" if recurrence_basis == 'count'
      rule << "UNTIL=#{recurrence_limit}" if recurrence_basis == 'limit'
      self.recurrence_rule = rule.join(';')
    else
      self.recurrence_rule = nil
    end
  end
  
  def recurrence_bounded?
    true if recurrence_period and not recurrence_count or recurrence_limit
  end
    
protected

  def get_uuid
    self.uuid ||= UUIDTools::UUID.timestamp_create.to_s
  end

  def set_default_status
    self.status ||= Status[:Published]
  end
  
  def date_format
    Radiant::Config['event_calendar.date_format'] || "%d %B %Y"
  end
  
  def short_date_format
    Radiant::Config['event_calendar.short_date_format'] || "%d/%m/%Y"
  end
  
  def time_format
    Radiant::Config['event_calendar.time_format'] || "%-1I:%M%p"
  end
  
  def round_time_format
    Radiant::Config['event_calendar.time_format'] || "%-1I%p"
  end
  

end

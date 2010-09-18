require 'uuidtools'
class Event < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper

  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :calendar
  has_site if respond_to? :has_site

  belongs_to :event_venue
  accepts_nested_attributes_for :event_venue, :reject_if => proc { |attributes| attributes.all? {|k,v| v.blank?} } # radiant 0.8.1 is using rails 2.3.4, which doesn't include the :all_blank sugar

  belongs_to :master, :class_name => 'Event'
  has_many :occurrences, :class_name => 'Event', :foreign_key => 'master_id', :dependent => :destroy
  has_many :recurrence_rules, :class_name => 'EventRecurrenceRule', :dependent => :destroy, :conditions => {:active => true}
  accepts_nested_attributes_for :recurrence_rules, :allow_destroy => true, :reject_if => lambda { |attributes| attributes['active'].to_s != '1' }

  validates_presence_of :uuid, :title, :start_date, :status_id
  validates_uniqueness_of :uuid

  before_validation :set_uuid
  before_validation :set_default_status
  after_save :update_occurrences

  default_scope :order => 'start_date ASC', :include => :event_venue
  named_scope :imported, { :conditions => ["status_id = ?", Status[:imported].to_s] }
  named_scope :submitted, { :conditions => ["status_id = ?", Status[:submitted].to_s] }
  named_scope :approved, { :conditions => ["status_id >= (?)", Status[:published].to_s] }
  named_scope :primary, { :conditions => "master_id IS NULL" }
  named_scope :recurrent, { :conditions => "master_id IS NOT NULL" }

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

  named_scope :within, lambda { |period| # CalendarPeriod object
    { :conditions => ['start_date > :start AND start_date < :finish', {:start => period.start, :finish => period.finish}] }
  }

  named_scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
    { :conditions => ['start_date > :start AND start_date < :finish', {:start => start, :finish => finish}] }
  }

  named_scope :future_and_current, {
    :conditions => ['(end_date > :now) OR (end_date IS NULL AND start_date > :now)', {:now => Time.now}]
  }

  named_scope :unfinished, lambda { |start| # datetimable object.
    { :conditions => ['start_date < :start AND end_date > :start', {:start => start}] }
  }

  named_scope :coincident_with, lambda { |start, finish| # datetimable objects.
    { :conditions => ['(start_date < :finish AND end_date > :start) OR (end_date IS NULL AND start_date > :start AND start_date < :finish)', {:start => start, :finish => finish}] }
  }

  named_scope :by_end_date,  { :order => "end_date ASC" }

  def self.in_the_last(period)           # seconds. eg calendar.occurrences.in_the_last(1.week)
    finish = Time.now
    start = finish - period
    between(start, finish)
  end

  def self.in_year(year)                 # just a number. eg calendar.occurrences.in_year(2010)
    start = DateTime.civil(year)
    finish = start + 1.year
    between(start, finish)
  end

  def self.in_month(year, month)          # numbers. eg calendar.occurrences.in_month(2010, 12)
    start = DateTime.civil(year, month)
    finish = start + 1.month
    between(start, finish)
  end

  def self.in_week(year, week)            # numbers, with a commercial week: eg calendar.occurrences.in_week(2010, 35)
    start = DateTime.commercial(year, week)
    finish = start + 1.week
    between(start, finish)
  end

  def self.on_day (year, month, day)      # numbers: eg calendar.occurrences.on_day(2010, 12, 12)
    start = DateTime.civil(year, month, day)
    finish = start + 1.day
    between(start, finish)
  end

  def self.future
    after(Time.now)
  end

  def self.past
    before(Time.now)
  end

  def self.as_months
    stack = {}
    find(:all).each_with_object({}) do |event, stack|
      y = event.start_date.year
      m = Date::MONTHNAMES[event.start_date.month]
      stack[y] ||= {}
      stack[y][m] ||= []
      stack[y][m].push event
    end
    stack
  end

  def category
    calendar.category if calendar
  end

  def slug
    calendar.slug if calendar
  end

  def description_paragraph
    if description =~ /\<p/
      description
    else
      "<p>#{description}</p>"
    end
  end

  def short_description(length=256, ellipsis="...")
    truncate(description, length, ellipsis)
  end

  def master?
    master.nil?
  end

  def occurrence?
    !master?
  end

  def location
    event_venue ? event_venue.to_s : read_attribute(:location)
  end

  def address
    event_venue ? event_venue.address : read_attribute(:location)
  end

  def postcode
    event_venue ? event_venue.postcode : read_attribute(:postcode)
  end

  def date
    start_date.to_datetime.strftime(date_format)
  end

  def month
    Date::MONTHNAMES[start_date.month]
  end

  def short_month
    Date::ABBR_MONTHNAMES[start_date.month]
  end

  def year
    start_date.year
  end

  def day
    Date::DAYNAMES[start_date.day]
  end

  def mday
    start_date.mday
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

  def last_day
    end_date.to_datetime.strftime(date_format)if end_date
  end

  def duration
    if end_date
      end_date - start_date
    else
      0
    end
  end

  def starts
    if all_day?
      "all day"
    else
      start_time
    end
  end

  def finishes
    if all_day?
      "all day"
    else
      end_time
    end
  end

  def summarize_start
    if one_day?
      "all day on #{date}"
    elsif all_day?
      "from #{date}"
    else
      "#{start_time} on #{date}"
    end
  end

  def summarize_period
    period = []
    if one_day?
      period << "all day on #{date}"
    elsif all_day?
      period << "from #{date} to #{end_date.to_datetime.strftime(date_format)}"
    elsif within_day?
      period << "#{start_time}"
      period << "to #{end_time}" if end_time
      period << "on #{date}"
    else
      period << "#{start_time} on #{date}"
      period << "to #{end_time} on #{end_date.to_datetime.strftime(date_format)}"
    end
    period.join(' ')
  end

  def url
    if url = read_attribute(:url)
      return nil if url.blank?
      url = "http://#{url}" unless url =~ /^(http:\/){0,1}\//
      url.strip
    end
  end

  def one_day?
    all_day? && within_day?
  end

  def within_day?
    (!end_date || start_date.to_date.jd == end_date.to_date.jd || end_date == start_date + 1.day)
  end

  # sometimes we need to filter an existing list to get the day's events
  # usually in a radius tag, to avoid going back to the database for each day in a list
  # so we call events.select {|e| e.on_this_day?(day) }

  def on_this_day?(date)
    if end_date
      start_date < date.end_of_day && end_date > date.beginning_of_day
    else
      start_date > date.beginning_of_day && start_date < date.end_of_day
    end
  end

  def in_this_month?(date)
    if end_date
      start_date < date.end_of_month && end_date > date.beginning_of_month
    else
      start_date > date.beginning_of_month && start_date < date.end_of_month
    end
  end

  def continuing?
    end_date && start_date < Time.now && end_date > Time.now
  end

  def editable?
    status != Status[:imported]
  end

  def recurs?
    master || occurrences.any?
  end

  def status
    Status.find(self.status_id)
  end

  def status=(value)
    self.status_id = value.id
  end

  def recurrence
    recurrence_rules.first.to_s
  end

  def add_recurrence(rule)
    self.recurrence_rules << EventRecurrenceRule.from(rule)
  end

  def to_ri_cal
    RiCal.Event do |cal_event|
      cal_event.uid = uuid
      cal_event.summary = title
      cal_event.description = description if description
      cal_event.dtstart =  (all_day? ? start_date.to_date : start_date) if start_date
      cal_event.dtend = (all_day? ? end_date.to_date : end_date) if end_date
      cal_event.url = url if url
      cal_event.rrules = recurrence_rules.map(&:to_ical) if recurrence_rules.any?
      cal_event.location = location if location
    end
  end

  def ical
    self.to_ri_cal.to_s
  end

  def self.create_from(cal_event)
    event = new({
      :uuid => cal_event.uid,
      :title => cal_event.summary,
      :description => cal_event.description,
      :location => cal_event.location,
      :url => cal_event.url,
      :start_date => cal_event.dtstart,
      :end_date => cal_event.dtend,
      :all_day => !cal_event.dtstart.is_a?(DateTime),
      :created_at => cal_event.dtstamp
    })
    event.status = Status[:imported]
    cal_event.rrule.each { |rule| event.add_recurrence(rule) }
    event
  rescue => error
    logger.error "Event import error: #{error}."
    raise
  end

  def update_from(cal_event)
    self.update_attributes({
      :title => cal_event.summary,
      :description => cal_event.description,
      :location => cal_event.location,
      :url => cal_event.url,
      :start_date => cal_event.dtstart,
      :end_date => cal_event.dtend,
      :all_day => !cal_event.dtstart.is_a?(DateTime)
    })
    self.status = Status[:imported]
    cal_event.rrule.each { |rule| self.add_recurrence(rule) }
    self
  rescue => error
    logger.error "Event update error: #{error}."
    raise
  end

protected

  def set_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s if uuid.blank?
  end

  def set_default_status
    self.status ||= Status[:Published]
  end

  # doesn't yet observe exceptions
  def update_occurrences
    occurrences.destroy_all
    if recurrence_rules.any?
      recurrence_horizon = Time.now + (Radiant::Config['event_calendar.recurrence_horizon'] || 10).to_i.years
      to_ri_cal.occurrences(:before => recurrence_horizon).each do |occ|
        occurrences.create!(self.attributes.merge(:start_date => occ.dtstart, :end_date => occ.dtend, :uuid => nil)) unless occ.dtstart == self.start_date
      end
    end
  end

  def date_format
    Radiant::Config['event_calendar.date_format'] || "%-1d %B"
  end

  def short_date_format
    Radiant::Config['event_calendar.short_date_format'] || "%-1d/%m/%Y"
  end

  def time_format
    Radiant::Config['event_calendar.time_format'] || "%-1I:%M%p"
  end

  def round_time_format
    Radiant::Config['event_calendar.round_time_format'] || "%-1I%p"
  end

  def dates_are_in_order

  end

end

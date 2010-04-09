class EventRecurrenceRule < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :event
  has_site if respond_to? :has_site
  
  def active
    new_record? ? false : read_attribute(:active)
  end

  def basis
    basis = read_attribute(:basis)
    return nil unless basis == 'count' || basis == 'limit'
    basis
  end
  
  def unbounded?
    basis.nil?
  end
  
  def single?
    true if basis == 'limit' && limiting_count == 1
  end

  def to_s
    summary = []
    if interval > 1
      unit = period.downcase.sub(/ly$/, '')
      unit = "day" if unit == 'dai'
      summary << "every #{interval} #{unit.pluralize}"
    else 
      summary << period.downcase
    end
    if unbounded?
      summary.last << ","
      summary << 'indefinitely'
    elsif basis == 'limit' && limiting_date
      summary << "until #{limiting_date.to_datetime.strftime('%d %B %Y')}" if limiting_date
    elsif basis == 'count' && limiting_count
      summary.last << ","
      summary << "#{limiting_count} times"
    end
    summary.join(' ')
  end
  
  def rule=(rule)
    rule = RiCal::PropertyValue::RecurrenceRule.convert(nil, rule) unless rule.is_a? RiCal::PropertyValue::RecurrenceRule
    self.period = rule.freq
    self.interval = rule.interval
    if rule.until
      self.basis = 'limit'
      self.limiting_date = rule.until.value
    elsif rule.count
      self.basis = 'count'
      self.limiting_count = rule.count
    end
  end
  
  def rule
    rule = RiCal::PropertyValue::RecurrenceRule.convert(nil, "") unless rule.is_a? RiCal::PropertyValue::RecurrenceRule
    rule.freq = period.upcase
    rule.until = limiting_date if basis == 'limit' && limiting_date
    rule.count = limiting_count if basis == 'count' && limiting_count
    rule.interval = interval
    rule
  end

  def self.from(rule)         # ical string or RiCal::PropertyValue::RecurrenceRule
    rrule = self.new
    rrule.rule = rule
    rrule.active = true
    rrule
  end
  
  def to_ical
    rule.to_ical
  end

end





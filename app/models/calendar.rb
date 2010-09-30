class Calendar < ActiveRecord::Base
  has_one :ical, :dependent => :destroy
  has_many :events, :dependent => :destroy
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_site if respond_to? :has_site

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_uniqueness_of :slug, :scope => :category

  accepts_nested_attributes_for :ical, :reject_if => proc { |attributes| attributes['url'].blank? }
  # validates_associated :ical
  
  named_scope :in_category, lambda { |category| # string. needs to match exactly
    { :conditions => [ "calendars.category = ?", category ] }
  }

  named_scope :with_slugs, lambda { |calendar_slugs| # array , or pipe-separated string
    slugs = calendar_slugs.split('|') unless slugs.is_a? Array
    { :conditions => [ slugs.map{"calendars.slug = ?"}.join(' OR '), *slugs ] }
  }

  named_scope :with_names_like, lambda { |calendar_names| # comma or pipe--separated string of (partial) names. eg. Calendar.with_names_like('team_')
    names = calendar_names.split(/[,\|]\s*/).map{|n| "%#{n}%"}
    { :conditions => [ names.map{"calendars.name LIKE ?"}.join(' OR '), *names ] }
  }
  
  def self.categories
    categories = find( :all, :select => "DISTINCT category" ).map(&:category)
  end
  
  def self.slugs
    slugs = find( :all, :select => "DISTINCT slug" ).map(&:slug)
  end

  def to_ics
    ical.to_ics if ical
  end
  
  def to_s
    self.name
  end
  
  def to_ri_cal
    RiCal.Calendar do |cal|
      events.primary.each do |event|
        cal.add_subcomponent(event.to_ri_cal)
      end
    end
  end

  def to_ical
    self.to_ri_cal.to_s
  end
  
end

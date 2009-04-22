class Calendar < ActiveRecord::Base
  has_one :ical, :dependent => :destroy
  has_many :events, :dependent => :destroy
  validates_associated :ical
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_uniqueness_of :slug, :scope => :category
  
  named_scope :in_category, lambda { |category| # string. needs to match exactly
    { :conditions => [ "calendars.category = ?", category ] }
  }

  named_scope :with_slugs, lambda { |calendar_slugs| # pipe-separated string of slugs
    slugs = calendar_slugs.split('|')
    { :conditions => [ slugs.map{"calendars.slug = ?"}.join(' OR '), *slugs ] }
  }

  named_scope :with_names_like, lambda { |calendar_names| # comma or pipe--separated string of (partial) names. eg. Calendar.with_names_like('team_')
    names = calendar_names.split(/[,\|]\s*/).map{|n| "%#{n}%"}
    { :conditions => [ names.map{"calendars.name LIKE ?"}.join(' OR '), *names ] }
  }
  
  def to_s
    self.name
  end

end

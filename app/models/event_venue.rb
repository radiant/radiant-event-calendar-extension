class EventVenue < ActiveRecord::Base
  has_many :events, :dependent => :nullify
  has_site if respond_to? :has_site
  default_scope :order => 'title asc'
  
  def to_s
    title
  end
  
  # location is the string read in automatically from ical subscriptions
  def title
    read_attribute(:title) || location
  end
  
end

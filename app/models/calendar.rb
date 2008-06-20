class Calendar < ActiveRecord::Base
  has_one :ical, :dependent => :destroy
  has_many :events, :dependent => :destroy
  validates_associated :ical
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_uniqueness_of :slug, :scope => :category
  
  def to_s
    self.name
  end

end

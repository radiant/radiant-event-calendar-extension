class EventVenue < ActiveRecord::Base
  has_many :events, :dependent => :nullify
  has_site if respond_to? :has_site
  validates_presence_of :title, :address
  default_scope :order => 'title asc'
  
  def to_s
    %{#{title}, #{address}}
  end
  
  def location
    address
  end
  def location=(location)
    address = location
  end
end

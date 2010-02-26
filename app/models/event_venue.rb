class EventVenue < ActiveRecord::Base
  has_many :events, :dependent => :nullify
  validates_presence_of :title, :address
  default_scope :order => 'title asc'
  
  def to_s
    %{#{title}, #{address}, #{postcode}}
  end
  
  def from
    #postcode check?
  end
end

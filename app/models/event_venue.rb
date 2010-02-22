class EventVenue < ActiveRecord::Base
  has_many :events
  validates_presence_of :title, :address
  
  def to_s
    %{#{title}, #{address}, #{postcode}}
  end
  
  def from
    #postcode check?
  end
end

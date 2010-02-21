class EventCategory < ActiveRecord::Base
  has_many :events
  validates_presence_of :title
end

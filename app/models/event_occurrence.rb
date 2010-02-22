class EventOccurrence < ActiveRecord::Base
  
  belongs_to :event
  belongs_to :calendar          # for efficient retrieval
  belongs_to :event_venue       # we can just grab occurrences
  
  is_site_scoped if respond_to? :is_site_scoped

  delegate :title, :description, :location, :postcode, :url, :keywords, :contact, :all_day, :to => :event

  before_validation_on_create :set_defaults
  
protected

  # the default occurrence just echoes the event
  # recurrences will override at least start_date.

  def set_defaults
    [:start_date, :end_date, :calendar_id, :event_venue_id].each do |col|
      self[col] ||= event.send(col)
    end
  end

end

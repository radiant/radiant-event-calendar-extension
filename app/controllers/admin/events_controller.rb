class Admin::EventsController < Admin::ResourceController
  paginate_models :per_page => 20
  prepend_before_filter :get_venue
  
  def load_models
    pp = pagination_parameters
    finder = @event_venue ? Event.at_venue(@event_venue) : Event.scoped({})
    unless params[:p]
      first_event = finder.future_and_current.first
      i = finder.index(first_event) || 0    # if there are no future events we revert to the first page
      p = (i / pp[:per_page].to_i) + 1
      pp[:page] = p if p && p > 1
    end
    self.models = finder.paginate(pp)
  end

protected
  
  def get_venue
    @event_venue = EventVenue.find_by_id(params[:event_venue_id]) if params[:event_venue_id]
    Rails.logger.warn "@event_venue is #{@event_venue.inspect}"
  end

end

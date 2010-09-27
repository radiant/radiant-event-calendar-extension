class Admin::EventsController < Admin::ResourceController
  paginate_models :per_page => 20
  
  def load_models
    pp = pagination_parameters
    unless params[:p]
      first_event = Event.future_and_current.first
      i = Event.all.index(first_event)
      p = (i / pp[:per_page].to_i) + 1
      pp[:page] = p if p && p > 1
    end
    self.models = Event.paginate(pp)
  end

end

class Admin::EventsController < Admin::ResourceController

  def load_models
    finder = params[:all] ? Event.all : Event.future_and_current
    self.models = finder.paginate(pagination_parameters)
  end

protected

  def pagination_parameters
    pp = pagination_defaults
    pp.keys.each { |k| pp[k] = params[k] unless params[k].blank? }
    pp[:order] = "#{params[:by]} #{params[:order] || 'ASC'}" if params[:by]
    pp
  end

  def pagination_defaults
    {
      :page => 1, 
      :per_page => Radiant::Config['event_calendar.per_page'] || 20,
      :order => "start_date ASC"
    }
  end

end

class Admin::EventsController < Admin::ResourceController
  paginate_models :per_page => 20
  
  def load_models
    finder = params[:all] ? Event.all : Event.future_and_current
    self.models = finder.paginate(pagination_parameters)
  end

end

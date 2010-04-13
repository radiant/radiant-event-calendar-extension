class Admin::EventsController < Admin::ResourceController

  def load_models
    finder = params[:all] ? Event.all : Event.future_and_current
    self.models = finder.paginate(pagination_parameters)
  end

end

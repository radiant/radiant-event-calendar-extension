class Admin::EventsController < Admin::ResourceController

  def load_models
    self.models = params[:all] ? Event.all : Event.future
  end

end

class Admin::EventVenuesController < Admin::ResourceController

  def load_models
    self.models = model_class.paginate(pagination_options)
  end

end

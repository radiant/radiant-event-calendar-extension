class Admin::EventsController < Admin::ResourceController

  def load_models
    finder = params[:all] ? Event.all : Event.future_and_current

    Rails.logger.warn "!!  filter_chain: #{self.class.filter_chain.map(&:method).inspect}"
    Rails.logger.warn "!!  respond_to? :pagination_options: #{(respond_to? :pagination_options).inspect}"
    Rails.logger.warn "!!  pagination_options: #{pagination_options.inspect}"
    
    self.models = finder.paginate(pagination_options)
  end

end

module ApplicationControllerExtensions
  def self.included(base)
    base.class_eval do
      attr_reader :pagination
      helper_method :pagination
      before_filter :set_pagination
    end
  end

  def set_pagination
    @pagination = pagination_defaults.merge({
      :page => params.delete(:page),
      :per_page => params.delete(:per_page)
    })
  end

  def pagination_defaults
    {
      :page => 1, 
      :per_page => request.params[:per_page] || Radiant::Config['pagination.per_page'] || 20
    }
  end
  
  def layout_for(area = :event_calendar)
    if defined? Site && current_site && current_site.respond_to?(:layout_for)
      current_site.layout_for(area)
    elsif area_layout = Radiant::Config["#{area}.layout"]
      area_layout
    elsif main_layout = Layout.find_by_name('Main')
      main_layout.name
    elsif any_layout = Layout.first
      any_layout.name
    end
  end

end

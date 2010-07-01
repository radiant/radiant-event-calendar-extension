class Admin::CalendarsController < Admin::ResourceController
  paginate_models
  before_filter :check_refreshments, :only => [:index, :show]

  def show
    @calendar = Calendar.find(params[:id])
    @year = params[:year] ? params[:year].to_i : Date.today.year
    @month = params[:month] ? params[:month].to_i : Date.today.month
    response_for :singular
  end
  
protected

  def check_refreshments
    Ical.check_refreshments
  end

end

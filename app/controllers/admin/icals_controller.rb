class Admin::IcalsController < Admin::ResourceController

  def refresh_all
    # This is the correct line for the agent to run.  
    # Calendar::refresh_all
    
    # We'll keep using this so we can keep an eye on the downlaod status until an agent and proper error checking is implemented.
    @icals = Ical.find(:all)
    @icals.each do |ical|
      ical.refresh
    end
    flash[:notice] = "iCal subscription refresh complete."
    redirect_to admin_calendars_path
  end 
  
  def refresh
    ical = Ical.find(params[:id])
    if response = ical.refresh
      flash[:notice] = ical.calendar.name + " calendar refreshed. #{response}"
    else
      flash[:notice] = "Error parsing " + ical.calendar.name + " calendar from iCal subscription."
    end
    redirect_to :back
  end
  
end

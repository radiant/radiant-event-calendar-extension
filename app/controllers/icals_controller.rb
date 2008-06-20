class IcalsController < ApplicationController

  def refresh_all
    # This is the correct line for the agent to run.  
    # Calendar::refresh_all
    
    # We'll keep using this so we can keep an eye on the downlaod status until an agent and proper error checking is implemented.
    @icals = Ical.find(:all)
    @icals.each do |ical|
      ical.refresh
    end
    flash[:notice] = "iCal subscription refresh complete."
    redirect_to calendars_path
  end 
  
  def refresh
    ical = Ical.find(params[:id])
    if ical.refresh
      flash[:notice] = ical.calendar.name + " calendar refreshed from iCal subscription ."
    else
      flash[:notice] = "Error parsing " + ical.calendar.name + " calendar from iCal subscription, check the iCal URL."
    end
    redirect_to calendars_path
  end
  
  def index
    @icals = Ical.find(:all)
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @icals.to_xml }
    end
  end

  def show
    @ical = Ical.find(params[:id])
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @ical.to_xml }
    end
  end

  def new
    @ical = Ical.new(:person_id=>params[:person_id])
  end

  def edit
    @ical = Ical.find(params[:id])
  end

  def create
    @ical = Ical.new(params[:ical])
    respond_to do |format|
      if @ical.save
        flash[:notice] = 'Ical was successfully created.'
        format.html { redirect_to ical_url(@ical) }
        format.xml  { head :created }
        # , :location => ical_url(@ical) 
        format.js { @status = flash[:notice] }
      else
        format.html { redirect_to new_ical_path() }
        format.xml  { render :xml => @ical.errors.to_xml }
      end
    end
  end

  def update
    @ical = Ical.find(params[:id])
    @status = "test"
    respond_to do |format|
      if @ical.update_attributes(params[:ical])
        flash[:notice] = 'Ical was successfully updated.'
        format.html { redirect_to ical_url(@ical) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ical.errors.to_xml }
      end
    end
  end

  def destroy
    @ical = Ical.find(params[:id])
    @ical.destroy
    respond_to do |format|
      format.html { redirect_to icals_url }
      format.xml  { head :ok }
    end
  end
  
end

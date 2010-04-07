class EventsController < ApplicationController
  require 'rss/maker'
  require "uri"
  helper_method :events, :continuing_events, :period, :calendars, :list_description

  radiant_layout { |controller| controller.layout_for :calendar }
  no_login_required

  # delivers designated lists of events in minimal formats

  def index
    respond_to do |format|
      format.html { }
      format.js {
        # for mapping purposes events are clustered by venue
        @venues = events.all.map(&:event_venue).uniq
        @venue_events = {}
        events.each do |e|
          @venue_events[e.event_venue.id] ||= []
          @venue_events[e.event_venue.id].push(e)
        end
      }
      format.rss {
        @title = Radiant::Config['event_calendar.feed_title'] || "#{Radiant::Config['admin.title']} Events"
        @version = params[:rss_version] || '2.0'
        @link = list_url
      }
      format.ics {
        headers["Content-disposition"] = %{attachment; filename="#{list_filename}.ics"}
      }
    end
  end
  
  def period
    return @period if @period
    this = Date.today
    if params[:day]
      start = Date.civil(params[:year] || this.year, params[:month] || this.month, params[:day])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_day)
    elsif params[:month]
      start = Date.civil(params[:year] || this.year, params[:month])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_month)
    elsif params[:year]
      start = Date.civil(params[:year])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_year)
    end
  end
  
  def calendars
    return @calendars if @calendars
    if params[:calendar_id]
      @calendars = [Calendar.find(params[:calendar_id])]
    elsif params[:slug]
      @calendars = Calendar.with_slugs(params[:slug])
    elsif params[:category]
      @calendars = Calendar.in_category(params[:category])
    end
  end
  
  def events
    return @events if @events
    @events = Event.scoped
    if period
      if period.bounded?
        @events = @events.between(period.start, period.finish) 
      elsif period.start
        @events = @events.after(period.start) 
      else
        @events = @events.before(period.finish) 
      end
    else
      @events = @events.future
    end
    @events = @events.approved if Radiant::Config['event_calendar.require_approval']
    @events = @events.in_calendars(calendars) if calendars
    @events = @events.paginate(pagination)
  end
  
  def continuing_events
    return @continuing_events if @continuing_events
    if period && period.start
      @continuing_events = Event.unfinished(period.start)
    else
      @continuing_events = []
    end
  end
  
  def list_description
    return @description if @description
    parts = []
    parts << period.description if period
    parts << "in #{calendars.to_sentence}" if calendars
    @description = parts.any? ? parts.join(' ') : "All future events"
  end
  
  def list_url
    host = request.host
    path = list_path
    URI::HTTP.build(:host => request.host, :path => path.join('/'))
  end
  
  def list_path
    path = []
    path << Radiant::Config['event_calendar.calendar_page'] || "calendar"
    [:category, :slug, :year, :month].each do |p|
      path << params[p] unless params[p].blank?
    end
    path
  end
  
  def list_filename
    prefix = Radiant::Config['event_calendar.filename_prefix'] || "events"
    name = [prefix]
    [:category, :slug, :year, :month].each do |p|
      name << params[p] unless params[p].blank?
    end
    name.join('_')
  end
  
  def url_for_date(date)
    
  end
  
  def url_for_month(date)
    
  end
  
end

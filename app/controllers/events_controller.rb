class EventsController < ApplicationController

  no_login_required
  before_filter :read_parameters, :only => :index

  # delivers designated lists of events in minimal formats
  # could also deliver html and might eventually take over from EventCalendarPage
  # but you get less direct front-end control that way.

  def index
    @events = event_finder
    @venues = @events.map(&:event_venue).uniq
    @venue_events = {}
    @events.each do |e|
      @venue_events[e.event_venue.id] ||= []
      @venue_events[e.event_venue.id].push(e)
    end
  end
    
  def read_parameters
    finder = Event.all
    if params[:year] && params[:month]
      start = Date.civil(params[:year].to_i, params[:month].to_i)
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_month)
    elsif params[:year]
      start = Date.civil(params[:year].to_i)
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_year)
    end
    if params[:calendar_id]
      @calendars = [Calendar.find(params[:calendar_id])]
    elsif params[:slug]
      @calendars = Calendar.with_slugs(params[:slug])
    elsif params[:category]
      @calendars = Calendar.in_category(params[:category])
    end
  end
  
  def event_finder
    ef = Event.future
    if @period
      if @period.bounded?
        ef = ef.between(@period.start, @period.finish) 
      elsif @period.start
        ef = ef.after(@period.start) 
      else
        ef = ef.before(@period.finish) 
      end
    end
    ef = ef.approved if Radiant::Config['event_calendar.require_approval']
    ef = ef.in_calendars(tag.locals.calendars) if @calendars && @calendars.any?
    ef
  end
  
end

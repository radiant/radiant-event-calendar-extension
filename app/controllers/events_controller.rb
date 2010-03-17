class EventsController < ApplicationController
  require 'rss/maker'
  require "uri"

  no_login_required
  before_filter :read_parameters, :only => :index

  # delivers designated lists of events in minimal formats
  # could also deliver html and might eventually take over from EventCalendarPage
  # but you get less direct front-end control that way.

  def index
    respond_to do |format|
      @events = event_finder
      @title = Radiant::Config['event_calendar.feed_title'] || "#{Radiant::Config['admin.title']} Events"
      @description = list_description
      @description = "All future events" if @description.blank?
      format.js {
        @venues = @events.map(&:event_venue).uniq
        @venue_events = {}
        @events.each do |e|
          @venue_events[e.event_venue.id] ||= []
          @venue_events[e.event_venue.id].push(e)
        end
      }
      format.rss {
        @version = params[:rss_version] || '2.0'
        @link = list_url
      }
      format.ics {
        headers["Content-disposition"] = %{attachment; filename="#{list_filename}.ics"}
      }
    end
  end
    
  def read_parameters
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
    ef = Event.scoped
    if @period
      if @period.bounded?
        ef = ef.between(@period.start, @period.finish) 
      elsif @period.start
        ef = ef.after(@period.start) 
      else
        ef = ef.before(@period.finish) 
      end
    else
      ef = ef.future
    end
    ef = ef.approved if Radiant::Config['event_calendar.require_approval']
    ef = ef.in_calendars(tag.locals.calendars) if @calendars && @calendars.any?
    ef
  end
  
  def list_description
    description = []
    description << @period.description if @period
    description << "in #{@calendars.to_sentence}" if @calendars
    description.join(' ')
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
  
end

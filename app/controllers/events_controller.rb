class EventsController < ApplicationController
  require 'rss/maker'
  require "uri"
  include ResourcePagination
  
  helper_method :events, :continuing_events, :period, :calendars, :list_description
  helper_method :url_for_date, :url_for_month, :url_without_period, :month_name, :short_month_name, :day_names
  before_filter :numerical_parameters
  
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
    if params[:mday]
      start = Date.civil(params[:year] || this.year, params[:month] || this.month, params[:mday])
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
    @events = @events.paginate(pagination_options)
  end
  
  def continuing_events
    return @continuing_events if @continuing_events
    if period && period.start
      @continuing_events = Event.unfinished(period.start).by_end_date
    else
      @continuing_events = Event.unfinished(Time.now).by_end_date
    end
  end
  
  def list_description
    return @description if @description
    parts = []
    parts << period.description if period
    parts << "in #{calendars.to_sentence}" if calendars
    @description = parts
  end
      
  def url_for_date(date)
    url_for(url_parts.merge({
      :mday => date.mday,
      :month => month_name(date.month).downcase,
      :year => date.year
    }))
  end
  
  def url_for_month(date)
    url_for(url_parts.merge({
      :mday => nil,
      :month => month_name(date.month).downcase,
      :year => date.year
    }))
  end
  
  def url_without_period
    url_for(url_parts.merge({
      :mday => nil,
      :month => nil,
      :year => nil
    }))
  end
  
  # this is a chain point for other extensions that add more ways to filter
  # ie, to start with, taggable_events
  
  def url_parts
    params.slice(:year, :month, :mday, :category, :slug, :calendar_id)   # Hash#slice is defined in will_paginate/lib/core_ext
  end
  
  def month_name(month)
    month_names[month]
  end
  
  def short_month_name(month)
    short_month_names[month]
  end
  
  def day_names
    return @day_names if @day_names
    @day_names ||= Date::DAYNAMES.dup
    @day_names.push(@day_names.shift) # Class::Date and ActiveSupport::CoreExtensions::Time::Calculations have different ideas of when is the start of the week. We've gone for the rails standard.  
    @day_names
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
  
protected
  
  def short_month_names
    @short_month_names ||= Date::ABBR_MONTHNAMES.dup
  end
  
  def month_names
    @month_names ||= Date::MONTHNAMES.dup
  end
  
  # months can be passed around either as names or numbers
  # any date part can be 'now' or 'next' for ease of linking
  # and everything is converted to_i to save clutter later
  
  def numerical_parameters
    if params[:month] && month_names.include?(params[:month].titlecase)
      params[:month] = month_names.index(params[:month].titlecase)
    end
    [:year, :month, :mday].select{|p| params[p] }.each do |p|
      params[p] = Date.today.send(p) if params[p] == 'now'
      params[p] = (Date.today + 1.send(p == :mday ? :day : p)).send(p) if params[p] == 'next'
      params[p] = params[p].to_i
    end
  end
  
end

class EventsController < SiteController
  require "uri"
  require "ri_cal"
  include Radiant::Pagination::Controller
  
  helper_method :events, :all_events, :continuing_events, :period, :calendars, :list_description
  helper_method :url_for_date, :url_for_month, :url_without_period, :calendar_parameters, :month_name, :short_month_name, :day_names
  before_filter :numerical_parameters
  
  radiant_layout { Radiant::Config['event_calendar.layout'] }
  no_login_required

  # delivers designated lists of events in minimal formats

  def index
    @seen_events = {}
    respond_to do |format|
      format.html {
        timeout = (Radiant::Config['event_calendar:cache_duration'] || self.class.cache_timeout || 3600).seconds
        expires_in timeout.to_i, :public => true, :private => false
      }
      format.js {
        render :json => events.to_json
      }
      format.rss {
        render :layout => false
      }
      format.ics {
        ical = RiCal.Calendar do |cal| 
          events.each { |event| cal.add_subcomponent(event.to_ri_cal) } 
        end
        send_data ical.to_s, :filename => "#{filename}.ics", :type => "text/calendar"
      }
    end
  end
  
  def show
    @event = Event.find(params[:id])
    respond_to do |format|
      format.html {
        timeout = (Radiant::Config['event_calendar:cache_duration'] || self.class.cache_timeout || 3600).seconds
        expires_in timeout.to_i, :public => true, :private => false
      }
      format.ics {
        ical = RiCal.Calendar { |cal| cal.add_subcomponent(@event.to_ri_cal) }
        send_data ical.to_s, :filename => "#{@event.title.slugify}.ics", :type => "text/calendar"
      }
    end
  end
  
  ### helper methods
  
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
    @events ||= event_finder.paginate(pagination_parameters)
  end
  
  def all_events
    @all_events ||= event_finder.all
  end
  
  def event_finder
    ef = Event.scoped({})
    if period
      if period.bounded?
        ef = ef.between(period.start, period.finish) 
      elsif period.start
        ef = ef.after(period.start) 
      else
        ef = ef.before(period.finish) 
      end
    else
      ef = ef.future
    end
    ef = ef.approved if Radiant::Config['event_calendar.require_approval']
    ef = ef.in_calendars(calendars) if calendars
    ef
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
    parts << (period ? period.description : t('event_page.coming_up'))
    parts << I18n.t('event_page.in_calendars', :calendars => calendars.to_sentence) if calendars
    @description = parts.join(' ')
  end
  
  # these methods build calendar links by using supplied parameters to amend the current parameter set
  # anything not mentioned is carried forward unchanged.
  # this is only slightly worthwhile here but gets much more useful when there are more ways to select events.
  
  # this whole mechanism should probably be moved into a helper.
      
  def url_for_date(date)
    url_for(url_parts({
      :mday => date.mday,
      :month => month_name(date.month).downcase,
      :year => date.year
    }))
  end
  
  def url_for_month(date)
    url_for(url_parts({
      :mday => nil,
      :month => month_name(date.month).downcase,
      :year => date.year
    }))
  end
  
  def url_without_period
    url_for(url_parts({
      :mday => nil,
      :month => nil,
      :year => nil
    }))
  end
  
  def query_string
    url_parts.map{|p| "#{p}=params[p]" }.join("&amp;")
  end
  
  def filename
    url_parts.map{|p| params[p] }.join("_")
  end
  
  # this is broken down into minimal parts to provide chain points for other extensions
  # that add more ways to filter. eg, to start with, taggable_events

  def calendar_parameters
    url_parts
  end
  
  def url_parts(amendments={})
    parts = params.slice(*calendar_parameter_names)   # Hash#slice is defined in will_paginate/lib/core_ext
    parts.merge(amendments)
  end
  
  def calendar_parameter_names
    [:year, :month, :mday, :category, :slug, :calendar_id]
  end
  
  def month_name(month)
    month_names[month]
  end
  
  def short_month_name(month)
    short_month_names[month]
  end
  
  def day_names
    return @day_names if @day_names
    @day_names ||= (I18n.t 'date.day_names').dup
    @day_names.push(@day_names.shift) # Class::Date and ActiveSupport::CoreExtensions::Time::Calculations have different ideas of when is the start of the week. We've gone for the rails standard.  
    @day_names
  end
  
protected
  
  def short_month_names
    @short_month_names ||= (I18n.t 'date.abbr_month_names').dup
  end
  
  def month_names
    @month_names ||= (I18n.t 'date.month_names').dup
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

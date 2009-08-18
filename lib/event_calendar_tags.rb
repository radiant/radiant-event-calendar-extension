require 'date'
require 'parsedate'
# require 'calendar_helper'

module EventCalendarTags
  include Radiant::Taggable
  # include CalendarHelper
  class TagError < StandardError; end
  
  # events:* tags
  # initiate an event search
  # and display the results
  
  desc %{ 
    Specify a set of events ready for listing, tabulation or other display.
    Normally but not necessarily called as r:events:each

    Note that this also sets a calendars variable - so within it you can call r:calendars:each to display calendar names or filtering links - and a calendar variable so that for each event you can also use r:calendar tags. Conversely, r:events will also do the right thing within an r:calendar or r:calendars:each tag.

    You can limit the set of events in various ways. To show only selected calendars, supply a name as 'calendar' or a comma-separated list of names as 'calendars'. Slugs work there too.
    
    <pre><code><r:events:each calendars="oneteam, anotherteam">...</r:events:each></code></pre>

    To limit to a particular period, any of these will work:
    
    * year, week, month and day are numerical attributes that designate a period. If any is specified then the others will default to the present. For any of them you can also supply 'now', 'next' or 'previous'.
    * years, months, weeks and days are numerical attributes that describe an interval from the present.
    * calendar_months is similar but describes a period from the start of the present month
    * from and to are date strings that describe a period. Either can also be set to 'now'.
    * until is like 'to' but forces 'from' to be 'now'.
    * since is like 'from' but forces 'to' to be 'now'.
        
    To display a list of all events in April 2010:

    <pre><code><r:events:each year="2010" month="4">...</r:events:each></code></pre>
    
    To display the same events in a calendar view:
    
    <pre><code><r:events:month year="2010" month="4" /></code></pre>
    
    To list events from the 'fell races' calendar for the next year:
    
    <pre><code><r:events:each calendar="fell races" months="12">...</r:events:each></code></pre>

    To show a stack of small calendar tables for the year with event links and styling:
    
    <pre><code><r:events:months calendar="fell races" months="12" compact="true" /></code></pre>
    
    If no period or interval is specified, we will return all events in the present month. Often all you want is this:
    
    <pre><code><r:events:month /></code></pre>
  }
  
  # I really want to the put the retrieval logic in the root 'events' tag, but the attributes don't seem to be available there
  
  tag "events" do |tag|
    tag.expand
  end
  
  tag "events:each" do |tag|
    tag.locals.events ||= get_events(tag)
    result = []
    tag.locals.previous_headers = {}
    tag.locals.events.each do |event|
      tag.locals.event = event
      tag.locals.calendar = event.calendar
      result << tag.expand
    end
    result
  end
     
  [:from, :to, :duration, :description].each do |attribute|
    # pass to the period
  end

  tag "events:period" do |tag|
    # nice description of the enclosed period
  end
  
  
  
  desc %{ 
    Renders a calendar table for a single month. Like all events: tags, if no period is specified, it defaults to the present month. 
    Usually you'll want to specify month and year attributes. An EventCalendar page will also obey month and year request parameters.
    If a period is specified longer than a month, we just render the first month: in that case you might want to use r:events:months to get several displayed at once.
    
    Usage:
    <pre><code><r:event:month [year=""] [month=""] [compact="true"] /></code></pre> 
    
  }
  tag "events:month" do |tag|
    attr = tag.attr.symbolize_keys
    tag.locals.events ||= get_events(tag)
    compact = attr[:compact] || tag.attr[:list_events].nil?
    table_class = compact ? 'small_month' : 'month'
    
    first_day = tag.locals.calendar_start ? tag.locals.calendar_start.beginning_of_month : tag.locals.period.begin_date.beginning_of_month
    last_day = first_day.end_of_month
    first_shown = first_day.beginning_of_week     # padding of period to show whole months
    last_shown = last_day.end_of_week
    previous = first_day - 1.day
    following = last_day + 1.day

    month_names = compact ? Date::ABBR_MONTHNAMES : Date::MONTHNAMES
    day_names = compact ? Date::DAYNAMES.map {|d| d.first} : Date::DAYNAMES
    day_names.push(day_names.shift) # Class::Date and ActiveSupport::CoreExtensions::Time::Calculations have different ideas of when is the start of the week. we've gone for the rails standard.
    
    cal = %(<table class="#{table_class}"><thead><tr>)
    cal << %(<th colspan="2" class="month_link"><a href="?year=#{previous.year}&amp;month=#{previous.month}">&lt; #{month_names[previous.month]}</a></th>) if attr[:month_links]
    cal << %(<th colspan="#{attr[:month_links] ? 3 : 7}" class="month_name">#{month_names[first_day.month]} #{first_day.year}</th>)
    cal << %(<th colspan="2" class="month_link"><a href="?year=#{following.year}&amp;month=#{following.month}">#{month_names[following.month]} &gt;</a></th>) if attr[:month_links]
    cal << %(</tr><tr class="day_name">)
    cal << day_names.map { |d| "<th scope='col'>#{d}</th>" }.join
    cal << "</tr></thead><tbody>"

    first_shown.upto(last_shown) do |day|
      events_today = tag.locals.events.select{ |e| e.start_date <= day + 1.day && e.end_date >= day }
      event_list = cell_text = date_label = ""
      cell_class = "day"
      cell_class += " other_month" if day.month != first_day.month
      unless compact && day.month != first_day.month
        cell_class += " weekend_day" if weekend?(day)
        cell_class += " today" if today?(day)
        cell_class += " weekend_today" if weekend?(day) && today?(day)
        date_label = day.mday
 
        if events_today.any?
          cell_class += " eventful"
          cell_class += " eventful_weekend" if weekend?(day)
          cell_class += events_today.map{|e| " #{e.calendar.slug}"}.join
          if compact
            date_label = %{<a href="#event_#{events_today.first.id}">#{date_label}</a>}
          else
            event_list << %{<ul>} << events_today.map { |e| "<li>#{e.title}</li>" }.join << "</ul>"
          end
        else
          cell_class += " uneventful"
        end
        date_label = %{<h4>#{date_label}</h4>} unless compact
        cell_text = %{<div class="event_holder">#{date_label}#{event_list}</div>}
      end
      cal << "<tr>" if day == day.beginning_of_week
      cal << %{<td class="#{cell_class}">#{cell_text}</td>}
      cal << "</tr>" if day == day.end_of_week
    end
    cal << %{</tbody></table>}
    cal
  end
  
  desc %{ 
    This is a shortcut that returns a set of tabulated months covering the period defined. It works in the same way as r:events:each but presents the results in a familiar calendar format.
    
    See r:events for attributes that specify the period, or try the examples.
    
    For the present month, pageable (if the page type is right), with the events listed for each day:
    
    <pre><code><r:events:as_calendar month="now" /></code></pre> 
    
    For the next three months, in little mini-tables that link to event anchors in a separate list
    
    <pre><code>
      <r:events:as_calendar calendar_months="3" compact="true" />
      <r:events:each months="3">
        <r:event:summary />
      </r:events:each>
    </code></pre>
    
    Note that if you set 'months=3' instead of 'calendar_months=3' then it means three months from today, which actually extends over four calendar months.
    
    Big months until the end of the year: 
    
    <pre><code><r:events:as_calendar until="12-12" /></code></pre>
    
    For more control and different views, see tags like r:events:year, r:events:month and r:events:week.
    
  }
  tag "events:as_calendar" do |tag|
    tag.locals.events ||= get_events(tag)
    result = ''
    this_month = nil
    tag.locals.period.begin_date.upto(tag.locals.period.end_date) do |day|
      if day.month != this_month
        tag.locals.calendar_start = day
        result << tag.render('events:month')
        this_month = day.month
      end
    end
    result
  end
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  # Event:* tags
  # display attributes of a single event 
  
  tag "event" do |tag|
    raise TagError, "can't have r:event without an event" unless tag.locals.event
    tag.expand
  end
  
  desc %{ 
    We display the content between these tags only when it has changed. 
    Here this is normally used to display the date above a list of events for that day but you can also list by calendar or by week, or whatever.
    You will want to pass a corresponding order parameter to r:events or r:calendar:events.
  }
  tag 'event:header' do |tag|
    previous_headers = tag.locals.previous_headers
    name = tag.attr['name'] || :unnamed
    restart = (tag.attr['restart'] || '').split(';')
    header = tag.expand
    unless header == previous_headers[name]
      previous_headers[name] = header
      unless restart.empty?
        restart.each do |n|
          previous_headers[n] = nil
        end
      end
      header
    end
  end

  [:id, :title, :description, :location, :url].each do |attribute|
    desc %{ 
      Renders the #{attribute} attribute of the current event.
      
      Usage:
      <pre><code><r:event:#{attribute} /></code></pre> 
    }
    tag "event:#{attribute}" do |tag|
      tag.locals.event.send(attribute)
    end
    
    desc %{ 
      Contents are rendered if the event has a #{attribute}.
      
      Usage:
      <pre><code><r:event:if_#{attribute}>...</r:event:if_#{attribute}></code></pre> 
    }
    tag "event:if_#{attribute}" do |tag|
      tag.expand if tag.locals.event.send(attribute)
    end
    
    desc %{ 
      Contents are rendered unless the event has a #{attribute}.
      
      Usage:
      <pre><code><r:event:unless_#{attribute}>...</r:event:unless_#{attribute}></code></pre> 
    }
    tag "event:unless_#{attribute}" do |tag|
      tag.expand unless tag.locals.event.send(attribute)
    end
  end
  
  desc %{ 
    If the event has a url, renders a link to that address around the title of the event. If not, just the title without a link.
    As usual, if the tag is double the contents are used instead, and any other attributes are passed through to the link tag, if any.
    
    Usage:
    <pre><code>
      <r:event:link />
      <r:event:link class="dated"><r:event:date />: <r:event:title /></r:event:link>
    </code></pre> 
  }
  tag "event:link" do |tag|
    options = tag.attr.dup
    text = tag.double? ? tag.expand : tag.render('event:title')
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    if tag.locals.event.url
      %{<a href="#{tag.render('url')}#{anchor}" #{attributes}>#{text}</a>}
    else
      %{<span #{attributes}>#{text}</span>}
    end
  end
  
  [:start, :end].each do |attribute|
    desc %{ 
      Renders the #{attribute} time of the current event with the specified strftime format. Default is 24 hour hh:mm.
      
      Usage:
      <pre><code><r:event:#{attribute} [format=""] /></code></pre> 
    }
    tag "event:#{attribute}" do |tag|
      date = tag.locals.event.send("#{attribute}_date")
      date.strftime(tag.attr['format'] || "%H:%M")
    end
  end

  desc %{ 
    Renders the start time of the current event with the specified strftime format. Unlike start and end, the default here is %m/%d/%Y

    Usage:
    <pre><code>
    <r:events:each>
      <r:event:header>
        <h3><r:event:date [format="%d %M"] /></h3>
        <ul>
      </r:event:header>
      <r:event:start /> <r:event:title /> 
    </r:events:each>
    </ul>
    </code></pre> 
  }
  tag "event:date" do |tag|
    tag.locals.event.start_date.strftime(tag.attr['format'] || "%m/%d/%Y")
  end
  
  desc %{ 
    Prints the day-of-month of the start date of the current event.
    Equivalent to calling <r:event:date format="%d" /> but a bit clearer.

    Usage:
    <pre><code><r:event:day /></code></pre> 
  }
  tag "event:day" do |tag|
    tag.locals.event.start_date.mday
  end

  desc %{ 
    Prints the ordinal form of the day-of-month of the start date of the current event.
    Equivalent to calling <r:event:date format="%d" /> but a bit clearer.

    Usage:
    <pre><code><r:event:day_ordinal /></code></pre> 
  }
  tag "event:day_ordinal" do |tag|
    tag.locals.event.start_date.mday.ordinalize
  end

  desc %{ 
    Prints the week-of-year of the start date of the current event.
    Equivalent to calling <r:event:date format="%W" /> but a bit clearer.

    Usage:
    <pre><code><r:event:week /></code></pre> 
  }
  tag "event:week" do |tag|
    tag.locals.event.start_date.cweek
  end

  desc %{ 
    Prints the name of the month of the start date of the current event.
    Equivalent to calling <r:event:date format="%B" /> but a bit clearer.

    Usage:
    <pre><code><r:event:month /></code></pre> 
  }
  tag "event:month" do |tag|
    Date::MONTHNAMES[tag.locals.event.start_date.month]
  end

  desc %{ 
    Prints the year of the start date of the current event.
    Equivalent to calling <r:event:date format="%Y" /> but a bit clearer.
    
    Usage:
    <pre><code><r:event:year /></code></pre> 
  }
  tag "event:year" do |tag|
    tag.locals.event.start_date.year
  end

  desc %{ 
    The date range of the event. If start and finish are the same, shows just a start time. 
    If they differ, shows a range using the format and separator specified.
    All day events just show "all day".

    Usage:
    <pre><code><r:event:period [format=""] [separator=""] /></code></pre>
  }
  tag "event:period" do |tag|
    format = tag.attr['format'] || "%H:%M"
    separator = tag.attr['separator'] || "-"
    if tag.locals.event.allday?
      result = "all day"
    elsif tag.locals.event.start_date.strftime("%x") == tag.locals.event.end_date.strftime("%x")
      result = tag.locals.event.start_date.strftime(format)
    else
      result = tag.locals.event.start_date.strftime(tagformat) << separator << tag.locals.event.end_date.strftime(format)
    end
  end
  
  desc %{ 
    Contents are rendered only if this is an all-day event.

    Usage:
    <pre><code><r:event:if_all_day>...</r:event:if_all_day></code></pre>
  }
  tag "event:if_all_day" do |tag|
    tag.expand if tag.locals.event.allday?
  end
  
  desc %{ 
    Contents are rendered only if this is not an all-day event.

    Usage:
    <pre><code><r:event:unless_all_day>...</r:event:unless_all_day></code></pre>
  }
  tag "event:unless_all_day" do |tag|
    tag.expand unless tag.locals.event.allday?
  end










  # Calendars:* tags
  # iterate over the set of calendars

  desc %{
    Loop over a set of calendars specified by the usual search conditions.

    *Usage:* 
    <pre><code><r:calendars:each>...</r:calendars:each></code></pre>
  }
  tag 'calendars' do |tag|
    tag.locals.calendars = Calendar.find(:all, calendars_find_options(tag))
    tag.expand
  end
  
  tag 'calendars:each' do |tag|
    result = []
    tag.locals.calendars.each do |cal|
      tag.locals.calendar = cal
      result << tag.expand
    end
    result
  end










  # Calendar:* tags
  # select and display attributes of a single calendar
  # many of these are shortcuts to events: tags that set a calendar parameter and pass through.

  tag 'calendar' do |tag|
    tag.locals.calendar ||= get_calendar(tag)
    raise TagError, "No calendar" unless tag.locals.calendar
    tag.attr['calendar'] = tag.locals.calendar.slug
    tag.expand
  end

  [:id, :name, :description, :category, :slug].each do |attribute|
    desc %{ 
      Renders the #{attribute} attribute of the current calendar.
      
      Usage:
      <pre><code><r:calendar:#{attribute} /></code></pre> 
    }
    tag "calendar:#{attribute}" do |tag|
      tag.locals.calendar.send(attribute)
    end
  end

  [:last_refresh_date, :last_refresh_count, :ical_url, :ical_username, :ical_password].each do |attribute|
    desc %{ 
      Renders the #{attribute} attribute of the ical subscription associated with the current calendar.
      
      Usage:
      <pre><code><r:calendar:#{attribute} /></code></pre> 
    }
    tag "calendar:#{attribute}" do |tag|
      tag.locals.calendar.ical.send(attribute)
    end
  end

  desc %{
    Loops over the events of the present calendar. 
    Takes the same sort and selection options as r:events (except for those that specify which calendars to show), and within it you can use all the usual r:event and r:calendar tags.

    *Usage:* 
    <pre><code><r:calendar:events:each>...</r:calendar:events:each></code></pre>
  }
  tag 'calendar:events' do |tag|
    tag.locals.events = get_events(tag)
  end

  tag 'calendar:events:each' do |tag|
    result = []
    tag.locals.events.each do |event|
      tag.locals.event = event
      result << tag.expand
    end
    result
  end

  # month, week and day tags 
  # tabulate a period and show any events in the current set that fall into that period

  [:year, :month, :week, :day].each do |period|
    desc %{ 
      Shortcut tag that renders a #{period} view of the current calendar with all contained events.
      On EventCalendar pages, these tags will obey relevant year, month, week and day request parameters.
      Any other period tags are ignored.
      
      Usage:
      <pre><code><r:calendar:#{period} [year=""] [month=""] [week=""] [day=""] /></code></pre> 
    }
  end

  tag "calendar:day" do |tag|
    tag.locals.period = period_from_parts(:day => tag.attr['day'], :month => tag.attr['month'], :year => tag.attr['year'])
    tag.render("events:day")
  end

  tag "calendar:month" do |tag|
    tag.locals.period = period_from_parts(:month => tag.attr['month'], :year => tag.attr['year'])
    tag.render("events:month")
  end

  tag "calendar:week" do |tag|
    tag.locals.period = period_from_parts(:week => tag.attr['week'], :year => tag.attr['year'])
    tag.render("events:week")
  end

  tag "calendar:year" do |tag|
    tag.locals.period = period_from_parts(:year => tag.attr['year'])
    tag.render("events:year")
  end
  
  private
  
    # set_period turns supplied attributes into a start and end point and returns a CalendarCalendarPeriod object
    # and so defines most of the attribute interface
  
    def set_period(tag)
      attr = tag.attr.symbolize_keys
      
      [:year, :month, :week, :day].each do |p|
        case attr[p]
        when 'now'
          marker = Date.today
        when 'next'
          marker = Date.today + 1.send(p)
        when 'previous'
          marker = Date.today - 1.send(p)
        end
        
        # nb. containing periods might have rolled over
        # so we must specify those too
        if marker
          case p
          when :year
            attr[:year] = marker.year
          when :month
            attr[:month] = marker.month
            attr[:year] = marker.year
          when :week
            attr[:week] = marker.cweek
            attr[:year] = marker.year
          when :day
            attr[:day] = marker.mday
            attr[:month] = marker.month
            attr[:year] = marker.year
          end
        end
      end
            
      # request parameters are accepted for attributes that have been specified in the tag
      # so for a pageable calendar you would want to use <r:events:month month="now" /> rather than relying on the default
      
      if self.class == EventCalendarPage
        params = @request.parameters.symbolize_keys
        logger.warn "!   reading request parameters"
        [:year, :month, :day, :years, :months, :days, :since, :until, :from, :to].select {|a| 
          defined? attr[a]
        }.each do |a| 
          attr[a] = params[a] unless params[a].nil? || params[a] == 'default' || params[a] == '0'
        end
      end

      period_from_interval(attr) || period_from_duration(attr) || period_from_parts(attr)
    end
    
    def period_from_interval(int={})
      return CalendarPeriod.new(Time.now, int[:until].to_date) if int[:until]
      return CalendarPeriod.new(int[:since].to_date, Time.now) if int[:since]
      return CalendarPeriod.new(int[:from].to_date, int[:to].to_date) if int[:from] && int[:to]
      nil
    end
    
    def period_from_duration(dur={})
      dur[:from] ||= Date.today
      if dur[:calendar_months]
        from = dur[:from].beginning_of_month
        to = from + dur[:calendar_months].to_i.months
        return CalendarPeriod.new(from, to - 1.day)   # -1 to bring us to the end of the last month rather than the first of the one after
      end
      return CalendarPeriod.new(dur[:from], dur[:from] + dur[:years].to_i.years) if dur[:years]
      return CalendarPeriod.new(dur[:from], dur[:from] + dur[:months].to_i.months) if dur[:months]
      return CalendarPeriod.new(dur[:from], dur[:from] + dur[:weeks].to_i.days) if dur[:weeks]
      return CalendarPeriod.new(dur[:from], dur[:from] + dur[:days].to_i.days) if dur[:days]
      nil
    end
    
    def period_from_parts(parts={})
      return CalendarPeriod.new(Date.civil(parts[:year], 1, 1), Date.civil(parts[:year], -1, -1)) if parts[:year] && !parts[:month]
      parts[:year] ||= Date.today.year
      parts[:month] ||= Date.today.month
      if parts[:day]
        day = Date.civil(parts[:year], parts[:month], parts[:day])
        return CalendarPeriod.new(day, day+1) 
      end
      return CalendarPeriod.new(Date.commercial(parts[:year], parts[:week], 1), Date.commercial(parts[:year], parts[:week], -1)) if parts[:week]
      return CalendarPeriod.new(Date.civil(parts[:year], parts[:month], 1))
    end
    
    def set_calendars(tag)
      attr = tag.attr.symbolize_keys
      if tag.locals.calendar  # either we're in a calendar:* shortcut or we're eaching calendars. either way, it's set for us and parameters have no effect
        return [tag.locals.calendar]
      elsif attr[:slugs] && attr[:slugs] != 'all'
        return Calendar.with_slugs(attr[:slugs])
      elsif attr[:calendars]
        return Calendar.with_names_like(attr[:calendars])
      elsif self.class == EventCalendarPage && category = @request.path_parameters[:url][1]
        finder = Calendar.in_category(category)
        if slug = @request.path_parameters[:url][2]
          finder = finder.with_slugs(slug) unless slug.blank? || slug == 'all'
        end
        return finder.find(:all)
      end
      Calendar.find(:all)
    end
    
    def get_events(tag)
      Ical.check_refreshments
      tag.locals.period ||= set_period(tag)
      tag.locals.calendars ||= set_calendars(tag)
      event_finder = Event.between(tag.locals.period.begin_date, tag.locals.period.end_date)
      event_finder = event_finder.in_calendars(tag.locals.calendars) if tag.locals.calendars

      tag.attr[:by] ||= 'start_date'
      tag.attr[:order] ||= 'asc'
      find_options = standard_find_options(tag).merge({:include => :calendar})
      event_finder.find(:all, find_options)
    end

    def get_calendar(tag)
      raise TagError, "'title' or 'id' attribute required" unless tag.attr['title'] or tag.attr['id']
      tag.locals.calendar || Calendar.find_by_title(tag.attr['title']) || Calendar.find_by_id(tag.attr['id'])
    end

    def standard_find_options(tag)
      attr = tag.attr.symbolize_keys
      by = attr[:by] || "name"
      order = attr[:order] || "asc"
      options = {
        :order => "#{by} #{order}",
        :limit => attr[:limit] || nil,
        :offset => attr[:offset] || nil
      }
    end

    def weekend?(date)
      [0,6].include?(date.wday)
    end

    def today?(date)
      date == ::Date.current
    end




end
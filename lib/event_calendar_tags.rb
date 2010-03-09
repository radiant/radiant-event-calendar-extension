require 'chronic'

module EventCalendarTags
  include Radiant::Taggable
  # include CalendarHelper
  class TagError < StandardError; end
  
  tag 'all_events' do |tag|
    tag.locals.events = Event.all
    tag.expand if tag.locals.events.any?
  end
  
  #### events:* tags
  #### initiate an event search and display the results
  
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
  
  # I really want to put the retrieval logic in the root 'events' tag, but the attributes aren't available there
  
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
  
  tag "if_events" do | tag|
    tag.locals.events ||= get_events(tag)
    tag.expand if tag.locals.events.any?
  end
  
  tag "unless_events" do | tag|
    tag.locals.events ||= get_events(tag)
    tag.expand unless tag.locals.events.any?
  end
  
  desc %{ 
    This is a shortcut that returns a set of tabulated months covering the period defined. 
    It works in the same way as r:events:each but presents the results in a familiar calendar format.
    
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
    
    Full size months until the end of the year: 
    
    <pre><code><r:events:as_calendar until="12-12" /></code></pre>
    
    For more control and different views, see tags like r:events:year, r:events:month and r:events:week.
  }
  tag "events:as_calendar" do |tag|
    attr = parse_boolean_attributes(tag)
    tag.locals.events ||= get_events(tag)
    result = ''
    this_month = nil
    tag.locals.period = period_from_events(tag.locals.events)
    tag.locals.period.start.upto(tag.locals.period.finish) do |day|
      if day.month != this_month
        this_month = day.month
        if !attr[:omit_empty] || tag.locals.events.any? {|event| event.in_this_month?(day) }
          tag.locals.calendar_start = day
          result << tag.render(attr[:compact] ? 'events:minimonth' : 'events:month', attr.dup)
        end
      end
    end
    result
  end

  desc %{
    Displays a standard pagination block for the presently defined event list. Will_paginate's @class@, @previous_label@,
    @next_label@, @inner_window@, @outer_window@, and @separator@ attributes are passed through.

    *Usage:* 
    <pre><code><r:events:pagination /></code></pre>
  }
  tag "events:pagination" do |tag|
    options = {}
    result = []
    entry_name = tag.attr['entry_name'] || 'item'
    [:class, :previous_label, :next_label, :inner_window, :outer_window, :separator, :per_page].each do |a|
      options[a] = tag.attr[a.to_s] unless tag.attr[a.to_s].blank?
    end
    result << %{<div class="pagination">}
    result << will_paginate(tag.locals.events, options.merge(:renderer => PaginationLinkRenderer.new(tag), :container => false))
    if tag.attr['with_summary'] != "false"
      result << %{<span class="summary">}
      result << page_entries_info(tag.locals.events, :entry_name => entry_name)         
      result << %{</span>}
    end
    result << %{</div>}
    result
  end
  
  desc %{
    Expands only if there are other pages to show.

    *Usage:* 
    <pre><code><r:events:if_paginated><h3>Pages</h3><r:events:pagination /></r:events:if_paginated></code></pre>
  }
  tag "events:if_paginated" do |tag|
    tag.expand if tag.locals.events.any? && (tag.locals.events.next_page || tag.locals.events.previous_page)
  end
  
  desc %{
    Renders a friendly description of the period currently being displayed.

    *Usage:* 
    <pre><code><r:events:list_description /></code></pre>
  }
  tag "events:list_description" do |tag|
    tag.locals.events ||= get_events(tag)
    filters = filters_applied(tag)
    paginated = true if (tag.locals.events.next_page || tag.locals.events.previous_page)
    html = %{<p class="list_summary">}
    html << %{Showing events #{filters.join(", ")}} if filters.any?
    html << %{<br />} if paginated && filters.any?
    html << %{Page #{tag.locals.events.current_page} of #{tag.locals.events.total_pages}.</span>} if paginated
    html << %{</p>}
    html
  end
  
  # chain anchor point
  
  def filters_applied(tag)
    html = []
    html << tag.locals.period.description if tag.locals.period
    html
  end

  #### Calendars:* tags
  #### iterate over the set of calendars

  desc %{
    Loop over a set of calendars specified by the usual search conditions.

    *Usage:* 
    <pre><code><r:calendars:each>...</r:calendars:each></code></pre>
  }
  tag 'calendars' do |tag|
    tag.locals.calendars ||= set_calendars(tag)
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

  desc %{
    Renders a sensible description of the currently displayed calendars, with links to each separate calendar.
    Pass with_subscription="true" to append a little ical subscription icon to each link.
    
    *Usage:* 
    <pre><code><r:calendars:summary /></code></pre>
  }
  tag 'calendars:summary' do |tag|
    result = "Showing events from the "
    result << tag.render('calendars:list', tag.attr.dup)
    result << ' '
    result << pluralize(tag.locals.calendars.length, 'calendar')
    result << %{ <a href="#{tag.render('url')}" class="note">(show all)</a>} if calendar_category
    result << '.'
    result
  end

  desc %{
    Renders a plain list (in sentence form) of the currently displayed calendars, with links to each separate calendar.
    Pass with_subscription="true" to append a little ical subscription icon to each link.
    
    *Usage:* 
    <pre><code><r:calendars:list /></code></pre>
  }
  tag 'calendars:list' do |tag|
    links = []
    with_subscription = (tag.attr['with_subscription'] == 'true')
    tag.locals.calendars.each do |calendar|
      tag.locals.calendar = calendar
      link = tag.render("calendar:link")
      link << tag.render("calendar:ical_icon") if with_subscription
      links << link
    end
    links.to_sentence
  end

  #### Calendar:* tags
  #### select and display attributes of a single calendar

  tag 'calendar' do |tag|
    tag.locals.calendar ||= get_calendar(tag)
    raise TagError, "No calendar" unless tag.locals.calendar
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

  [:last_refresh_date, :last_refresh_count, :url, :username, :password].each do |attribute|
    desc %{ 
      Renders the #{attribute} attribute of the ical subscription associated with the present calendar.
      
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
    tag.expand
  end

  tag 'calendar:events:each' do |tag|
    tag.locals.events ||= get_events(tag)
    result = []
    tag.locals.previous_headers = {}
    tag.locals.events.each do |event|
      tag.locals.event = event
      result << tag.expand
    end
    result
  end

  desc %{ 
    Renders the address that would be used to display the current calendar by itself on the current page.
    If the page isn't an EventCalendar page, this will still work but the destination probably won't.
    
    Usage:
    <pre><code><r:calendar:url /></code></pre> 
  }
  tag "calendar:url" do |tag|
    clean_url([tag.locals.page.url, tag.locals.calendar.category, tag.locals.calendar.slug].join('/'))
  end

  desc %{ 
    Renders a link to the address that would be used to display the current calendar by itself on the current page.
    Attributes and contained text are passed through exactly as for other links.
    
    If the page isn't an EventCalendar page, this will still work but the destination probably won't.
    
    Usage:
    <pre><code><r:calendar:link /></code></pre> 
  }
  tag "calendar:link" do |tag|
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('calendar:name')
    %{<a href="#{tag.render('calendar:url')}#{anchor}"#{attributes}>#{text}</a>}
  end

  desc %{
    Renders the path to the local .ics file for this calendar, suitable for read-only subscription in iCal or other calendar programs.
    
    Usage:
    <pre><code><r:calendar:ical_url /></code></pre> 
  }
  tag "calendar:ical_url" do |tag|
    tag.locals.calendar.to_ics
  end

  desc %{
    Renders a link to the local .ics file for this calendar, suitable for read-only subscription in iCal or other calendar programs.
    Link attributes are passed through as usual.
    
    Usage:
    <pre><code><r:calendar:ical_link /></code></pre> 
  }
  tag "calendar:ical_link" do |tag|
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('calendar:name')
    %{<a href="#{tag.render('calendar:ical_url')}#{anchor}"#{attributes}>#{text}</a>}
  end

  desc %{
    Renders a small graphical link to the local .ics file for this calendar.
    
    Usage:
    <pre><code><r:calendar:ical_icon /></code></pre> 
  }
  tag "calendar:ical_icon" do |tag|
    text = tag.attr['text'] || ''
    %{<a href="#{tag.render('calendar:ical_url')}" class="ical"><img src="/images/event_calendar/ical16.png" alt="subscribe to #{tag.render('calendar:name')}" width="16" height="16" /> #{text}</a>}
  end

  #### Event:* tags
  #### display attributes of a single event 

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
    previous_headers = tag.locals.previous_headers || {}
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

  #todo: venue:* tags
  
  desc %{ 
    If the current event has a venue, this renders a sensible description and link. If not, it returns the location string.

    Usage:
    <pre><code><r:event:venue /></code></pre> 
  }
  tag "event:venue" do |tag|
    if venue = tag.locals.event.event_venue
      if venue.url
        %{<a href="#{venue.url}">#{venue.title}</a>, #{venue.address}}
      else
        %{#{venue.title}, #{venue.address}}
      end
    else
      tag.render('event:location')
    end
  end

  desc %{ 
    If the event has a url, renders a link to that address around the title of the event. If not, just the title without a link.
    As usual, if the tag is double the contents are used instead, and any other attributes are passed through to the link tag.

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
  
  desc %{ 
    Renders a standard block listing the event and adding whatever links and descriptions are available.
    
    Supply with_month="true" or with_year="true" to show more date information. Supply with_time="false" if you don't want to show the start time.
    
    This may well be all you need:
    <pre><code>
      <r:events:each year="now" />
        <r:events:header name="month"><r:event:month /></r:events:header>
        <r:event:summary />
      </r:events:each />
    </code></pre> 
  }
  tag "event:summary" do |tag|
    options = tag.attr.dup
    result = %{
      <li class="event" id ="event_#{tag.render('event:id')}">
        <span class="date">#{tag.render('event:day_ordinal')}}
    result << %{ #{tag.render('event:month')}} if options['with_month'] == 'true'
    result << %{ #{tag.render('event:year')}} if options['with_year'] == 'true'
    result << %{ at #{tag.render('event:start')}} unless options['with_time'] == 'false'
    result << %{</span>
        #{tag.render('event:link', options.merge({'class' => 'title'}))}
    }
    result << %{<br /><span class="location">#{tag.render('event:location')}</span>} if tag.locals.event.location
    result << %{<br /><span class="description">#{tag.render('event:description')}</span>} if tag.locals.event.description
    result << %{</li>}
    result
  end

  desc %{ 
    Renders a sensible presentation of the time of the event. This is usually all you need, as it will do the right thing with all-day events.
      
    The presentation is minimal: 10:00am will be shortened to 10am.

    Usage:
    <pre><code><r:event:time />: <r:event:title /></code></pre> 
  }
  tag "event:time" do |tag|
    if tag.locals.event.all_day?
      "All day"
    else
      tag.locals.event.start_time
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
    Renders the start time of the current event with the specified strftime format. Unlike start and end, the default here is '%m/%d/%Y'

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
    Prints the day-of-week of the start date of the current event.
    Equivalent to calling <r:event:date format="%A" />.
    For the short form, set short="true"

    Usage:
    <pre><code><r:event:weekday [short="true"] /></code></pre> 
  }
  tag "event:weekday" do |tag|
    tag.attr['short'] == 'true' ? Date::ABBR_DAYNAMES[tag.locals.event.start_date.wday] : Date::DAYNAMES[tag.locals.event.start_date.wday]
  end

  desc %{ 
    Prints the day-of-month of the start date of the current event.
    Equivalent to calling <r:event:date format="%d" />.
    Supply zeropad="true" to get 1 as 01.

    Usage:
    <pre><code><r:event:day /></code></pre> 
  }
  tag "event:day" do |tag|
    d = tag.locals.event.start_date.mday
    if tag.attr['zeropad'] == 'true'
      "%02d" % d
    else
      d
    end
  end

  desc %{ 
    Prints the ordinal form of the day-of-month of the start date of the current event.

    Usage:
    <pre><code><r:event:day_ordinal /></code></pre> 
  }
  tag "event:day_ordinal" do |tag|
    tag.locals.event.start_date.mday.ordinalize
  end

  desc %{ 
    Prints the week-of-year of the start date of the current event.
    Equivalent to calling <r:event:date format="%W" />.

    Usage:
    <pre><code><r:event:week /></code></pre> 
  }
  tag "event:week" do |tag|
    tag.locals.event.start_date.cweek
  end

  desc %{ 
    Prints the name of the month of the start date of the current event.
    Equivalent to calling <r:event:date format="%B" />.

    Usage:
    <pre><code><r:event:month /></code></pre> 
  }
  tag "event:month" do |tag|
    Date::MONTHNAMES[tag.locals.event.start_date.month]
  end

  desc %{ 
    Prints the year of the start date of the current event.
    Equivalent to calling <r:event:date format="%Y" />.

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
    if tag.locals.event.all_day?
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

  desc %{ 
    Returns a day-and-date stamp suitable for CSS styling.
    Supply a 'class' parameter to add classes to the containing div.

    Usage:
    <pre><code><r:event:datemark /></code></pre>
  }
  tag "event:datemark" do |tag|
    html = ""
    html << _datemark(tag.locals.event.start_date)
    if tag.locals.event.end_date && tag.locals.event.start_date.mday != tag.locals.event.end_date.mday
      html << %{<span class="conjunction">to</span>}
      html << _datemark(tag.locals.event.end_date)
    end
    html
  end
  
  def _datemark(date=Time.now)
    %{
      <div class="datemark"><span class="month">#{Date::ABBR_MONTHNAMES[date.month]}</span><span class="dom">#{"%02d" % date.mday}</span></div>
    }
  end
    
  
  # calendar month blocks large and small. need some drying.
  
  desc %{ 
    Renders a minimal calendar table for a single month. Like all events: tags, if no period is specified, it defaults to the present month. 
    Usually you'll want to specify month and year attributes. An EventCalendar page will also obey month and year request parameters.
    If a period is specified longer than a month, we just render the first month: in that case you might want to use r:events:months to get several displayed at once.
    
    Usage:
    <pre><code><r:events:minimonth [year=""] [month=""] /></code></pre> 
    
  }
  tag "events:minimonth" do |tag|
    attr = parse_boolean_attributes(tag)
    tag.locals.events ||= get_events(tag)
    
    first_day = tag.locals.calendar_start ? tag.locals.calendar_start.beginning_of_month : tag.locals.period.start.beginning_of_month
    last_day = first_day.end_of_month
    first_shown = first_day.beginning_of_week     # padding of period to show whole months
    last_shown = last_day.end_of_week
    previous = first_day - 1.day
    following = last_day + 1.day

    with_paging = attr[:month_links] == 'true'
    with_list = attr[:event_list] == 'true'
    with_subscription = attr[:subscription_link] == 'true'
    
    cal = %(<table class="minimonth"><thead><tr>)
    cal << %(<th class="month_link"><a href="#{tag.locals.page.url(:year => previous.year, :month => previous.month)}" title="#{month_names[previous.month]}" class="previous">&lt;</a></th>) if with_paging
    cal << %(<th colspan="#{with_paging ? 5 : 7}" class="month_name">)
    cal << %(<a href="#{tag.locals.page.url(:year => first_day.year, :month => first_day.month)}">) if with_paging
    cal << %(#{month_names[first_day.month]} #{first_day.year})
    cal << %(</a>) if with_paging
    cal << %(</th>)
    cal << %(<th class="month_link"><a href="#{tag.locals.page.url(:year => following.year, :month => following.month)}" title="#{month_names[following.month]}" class="next">&gt;</a></th>) if with_paging
    cal << %(</tr><tr>)
    cal << day_names.map { |d| %{<th class="day_name" scope="col">#{d.first}</th>} }.join
    cal << "</tr></thead><tbody>"

    first_shown.upto(last_shown) do |day|
      events_today = tag.locals.events.select{ |e| e.on_this_day?(day) }
      event_list = cell_text = date_label = ""
      cell_class = "day"
      cell_class += " today" if today?(day)
      cell_class += " past" if day < Date.today
      cell_class += " future" if day > Date.today
      cell_class += " other_month" if day.month != first_day.month
      unless day.month != first_day.month
        cell_class += " weekend_day" if weekend?(day)
        cell_class += " weekend_today" if weekend?(day) && today?(day)
        date_label = day.mday
 
        if events_today.any?
          cell_class += " eventful"
          cell_class += " eventful_weekend" if weekend?(day)
          cell_class += events_today.map{|e| " #{e.slug}"}.join
          date_label = %{<a href="#event_#{events_today.first.id}">#{date_label}</a>}
        else
          cell_class += " uneventful"
        end
        cell_text = %{#{date_label}#{event_list}}
      end
      cal << "<tr>" if day == day.beginning_of_week
      cal << %{<td class="#{cell_class}">#{cell_text}</td>}
      cal << "</tr>" if day == day.end_of_week
    end
    if with_list
      cal << %{<tr><td colspan="7" class="event_list"><ul>}
        tag.locals.events.each do |event|
          tag.locals.event = event
          cal << tag.render('event:summary')
        end
      cal << "</ul>"
      cal << %{<p>#{tag.render('calendar:ical_icon', tag.attr.merge("text" => "Subscribe to calendar"))}} if with_subscription
      cal << "</td></tr>"
    end
    cal << %{</tbody></table>}
    cal
  end
    
  desc %{ 
    Renders a full calendar table for a single month. Like all events: tags, if no period is specified, it defaults to the present month. 
    Usually you'll want to specify month and year attributes. An EventCalendar page will also obey month and year request parameters 
    but only if the corresponding attributes have been specified.
    
    If a period is specified longer than a month, we just render the first month.
    
    If you use 'previous', 'now' and 'next' in your period attributes, an EventCalendar page will show the right period relative to input.
    
    Usage:
    <pre><code><r:event:month [year=""] [month=""] [compact="true"] /></code></pre> 
    
  }
  tag "events:month" do |tag|
    attr = parse_boolean_attributes(tag)
    tag.locals.events ||= get_events(tag)
    table_class = 'month'
    
    first_day = tag.locals.calendar_start ? tag.locals.calendar_start.beginning_of_month : tag.locals.period.start.beginning_of_month
    first_shown = first_day.beginning_of_week     # padding of period to fill month table
    last_day = first_day.end_of_month
    last_shown = last_day.end_of_week
    previous = first_day - 1.day
    following = last_day + 1.day

    month_names = Date::MONTHNAMES.dup
    day_names = Date::DAYNAMES.dup
    day_names.push(day_names.shift) # Class::Date and ActiveSupport::CoreExtensions::Time::Calculations have different ideas of when is the start of the week. We've gone for the rails standard.
    
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
      cell_class += " weekend_day" if weekend?(day)
      cell_class += " today" if today?(day)
      cell_class += " weekend_today" if weekend?(day) && today?(day)
      date_label = day.mday

      if events_today.any?
        cell_class += " eventful"
        cell_class += " eventful_weekend" if weekend?(day)
        cell_class += events_today.map{|e| " #{e.calendar.slug}"}.join
        event_list << %{<ul>} << events_today.map { |e| %{<li><span class="time">#{e.nice_start_time}:</span> #{e.title}</li>} }.join << "</ul>"
      else
        cell_class += " uneventful"
      end
      
      date_label = %{<h4>#{date_label}</h4>}
      cell_text = %{<div class="event_holder">#{date_label}#{event_list}</div>}
      cal << "<tr>" if day == day.beginning_of_week
      cal << %{<td class="#{cell_class}">#{cell_text}</td>}
      cal << "</tr>" if day == day.end_of_week
    end
    cal << %{</tbody></table>}
    cal
  end
  
  tag "calendar_periods" do |tag|
    html = "<ul>"
    stack = Event.as_months
    stack.keys.sort.each do |year|
      Date::MONTHNAMES.each do |month|
        html << %{<li><strong><a href="#{tag.locals.page.url(:year => year, :month => month)}">#{month} #{year}</a></strong> #{stack[year][month].length} events</li>} if stack[year][month] && stack[year][month].any?
      end
    end
    html << "</ul>"
    html
  end
  
  tag "requested_month" do |tag|
    Date::MONTHNAMES[calendar_month.to_i] if respond_to?(:calendar_month) && calendar_month
  end
  
  tag "requested_year" do |tag|
    calendar_year if respond_to?(:calendar_year) && calendar_year
  end
  
  
  
  
  
  
  
  
private

  # parse_boolean_attributes turns "true" into true and everything else into false
  # and incidentally symbolizes the keys
  
  def parse_boolean_attributes(tag)
    attr = tag.attr.symbolize_keys
    [:month_links, :date_links, :event_links, :compact].each do |param|
      attr[param] = false unless attr[param] == 'true'
    end
    attr
  end

  # these calculations all return a CalendarPeriod object, which is really just a beginning and end marker with some useful operations

  def set_period(tag)
    attr = tag.attr.symbolize_keys
    if self.class == EventCalendarPage && period = self.calendar_period
      return period
    end

    date_parts = [:year, :month, :week, :day]
    interval_parts = [:months, :calendar_months, :days, :since, :until, :from, :to]
    relatives = {'previous' => -1, 'now' => 0, 'next' => 1}

    # 1. fully specified period: any numeric date part found
    #    eg. <r:events:each year="2010" month="3">

    specified_date_parts = date_parts.select {|p| attr[p] && attr[p] == attr[p].to_i.to_s}
    if specified_date_parts.any?
      return period_from_parts(attr.slice(*specified_date_parts))
    end
    
    # 2. relative period: any relative date part specified (and no numeric date part)
    #    eg. <r:events:each month="now"> or <r:events:each month="next">
    
    relative_date_parts = date_parts.select {|p| relatives.keys.include? attr[p]}
    # if more than one - which there shouldn't be - we take the finest.
    if p = relative_date_parts.last   
      
      # get a present period with the right resolution
      relative_date_parts.each {|k,v| parts[k] = Date.today.send(k) unless parts[k].to_i.to_s == parts[k]}
      period = period_from_parts(relative_date_parts)

      # and then shift it in the right direction by the right amount:
      period += 1.send(p) if attr[p] == 'next'
      period -= 1.send(p) if attr[p] == 'previous'
      return period
    end

    # 3. relative interval
    #    eg. <r:events:each months="3"> or <r:events:each since="12/12/1969">
    #    any date string understood by chronic should be ok
    
    specified_interval_parts = interval_parts.select {|p| !attr[p].blank?}
    if specified_interval_parts.any?
      parts = attr.slice(*specified_interval_parts)
      return period_from_interval(parts)
    end
    
    # overall default will be to show (paginated) all future events
    period_from_interval(:from => Date.today)
  end

  def period_from_parts(parts={})
    parts.each {|k,v| parts[k] = parts[k].to_i}
    return CalendarPeriod.from(Date.civil(parts[:year], 1, 1), 1.year) if parts[:year] and not parts[:month]
    parts[:year] ||= Date.today.year
    return CalendarPeriod.from(Date.civil(parts[:year], parts[:month], 1), 1.month - 1.day) if parts[:month] && !parts[:week] && !parts[:day]
    parts[:month] ||= Date.today.month
    return CalendarPeriod.from(Date.commercial(parts[:year], parts[:week], 1), 1.week ) if parts[:week]
    return CalendarPeriod.from(Date.civil(parts[:year], parts[:month], parts[:day]), 1.day) if parts[:day]

    # default from parts is the present month
    return CalendarPeriod.from(Date.civil(parts[:year], parts[:month], 1), 1.month)
  end
  
  def period_from_interval(parts={})
    # from and to fully specified (including since and until as they are always relative to the present)
    return CalendarPeriod.between(Time.now, Chronic.parse(parts[:until])) if parts[:until]
    return CalendarPeriod.between(Chronic.parse(parts[:since]), Time.now) if parts[:since]
    return CalendarPeriod.between(Chronic.parse(parts[:from]), Chronic.parse(parts[:to])) if parts[:from] && parts[:to]

    # starting point defaults to now
    parts[:from] = Date.today if parts[:from].blank? || parts[:from] == 'now'
    from = Chronic.parse(parts[:from])
    
    # start moves to the first of the month if we're displaying calendar months
    return CalendarPeriod.from(from.beginning_of_month, parts[:calendar_months].to_i.months - 1.day) if parts[:calendar_months]
    
    # and in the end it's just a question of how much of the future to show
    return CalendarPeriod.from(from, parts[:years].to_i.years) if parts[:years]
    return CalendarPeriod.from(from, parts[:months].to_i.months) if parts[:months]
    return CalendarPeriod.from(from, parts[:weeks].to_i.weeks) if parts[:weeks]
    return CalendarPeriod.from(from, parts[:days].to_i.days) if parts[:days]
    
    # default is all future
    logger.warn "!!  defaulting to show all future events. parts[:from] is #{parts[:from].inspect} and parsed is #{from}"
    
    return CalendarPeriod.from(from)
  end
  
  # If no period has been specified then we may need to examine the current page of events to work out which month tables to display
  def period_from_events(events=[])
    if events.any?
      period_from_interval :from => events.first.start_date, :to => events.last.start_date
    end
  end

  # filter by calendar
  # returns a simple list which can be passed to Event.in_calendar

  def set_calendars(tag)
    attr = tag.attr.symbolize_keys
    if tag.locals.calendar  # either we're inside an r:calendar tag or we're eaching calendars. either way, it's set for us and parameters have no effect
      return [tag.locals.calendar]
    elsif attr[:slugs] && attr[:slugs] != 'all'
      return Calendar.with_slugs(attr[:slugs])
    elsif attr[:calendars]
      return Calendar.with_names_like(attr[:calendars])
    elsif self.class == EventCalendarPage 
      calendar_set
    else
      Calendar.find(:all)
    end
  end
  
  # combines all the scopes that have been set 
  # and returns a list of events
  
  def get_events(tag)
    Ical.check_refreshments
    tag.locals.period ||= set_period(tag)
    tag.locals.calendars ||= set_calendars(tag)
    ef = event_finder(tag)
    tag.attr[:by] ||= 'start_date'
    tag.attr[:order] ||= 'asc'
    retrieval_options = standard_find_options(tag).merge(pagination_defaults)
    ef.paginate(retrieval_options)
  end

  # other extensions - eg taggable_events - will chain the event_finder to add more scopes

  def event_finder(tag)
    if tag.locals.period.bounded?
      ef = Event.between(tag.locals.period.start, tag.locals.period.finish) 
    elsif tag.locals.period.start
      ef = Event.after(tag.locals.period.start) 
    else
      ef = Event.before(tag.locals.period.finish)
    end
    ef = ef.approved if Radiant::Config['event_calendar.require_approval']
    ef = ef.in_calendars(tag.locals.calendars) if tag.locals.calendars
    ef
  end

  def get_calendar(tag)
    raise TagError, "'title' or 'id' attribute required" unless tag.locals.calendar || tag.attr['title'] || tag.attr['id']
    tag.locals.calendar || Calendar.find_by_name(tag.attr['name']) || Calendar.find_by_id(tag.attr['id'])
  end

  def standard_find_options(tag)
    attr = tag.attr.symbolize_keys
    by = attr[:by] || "name"
    order = attr[:order] || "asc"
    {
      :order => "#{by} #{order}",
      :limit => attr[:limit] || nil,
      :offset => attr[:offset] || nil
    }
  end

  def pagination_defaults
    p = request.params[:page]
    p = 1 if p.blank? || p == 0
    return {
      :page => calendar_page || 1, 
      :per_page => request.params[:per_page] || Radiant::Config['event_calendar.per_page'] || 10
    }
  end

  def weekend?(date)
    [0,6].include?(date.wday)
  end

  def today?(date)
    date == ::Date.current
  end

  def pluralize(count, singular, plural = nil)
    (count == 1 || count == '1') ? singular : (plural || singular.pluralize)
  end

end
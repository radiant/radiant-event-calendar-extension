require 'rack/utils'

class EventCalendarPage < Page
  include WillPaginate::ViewHelpers

  attr_accessor :filters, :calendar_parameters, :calendar_filters, :calendar_year, :calendar_month, :calendar_page, :calendar_category, :calendar_slug, :calendar_period

  description %{ Create a viewer for calendar data. }

  def self.sphinx_indexes
    []
  end

  def cache?
    false
  end

  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    my_url = self.url
    if url =~ /^#{Regexp.quote(my_url)}(.*)/
      read_parameters($1)
      self
    else
      super
    end
  end
  
  def read_parameters(path)
    @calendar_parameters = []
    unless path.blank?
      parts = path.split(/\/+/)
      @calendar_page = parts.pop if parts.last =~ /^\d{1,3}$/
      parts.each do |part|
        if part.match(/^\d\d\d\d$/)
          @calendar_year = part
        elsif Date::MONTHNAMES.include?(part.titlecase)
          @calendar_month = Date::MONTHNAMES.index(part.titlecase)
        elsif Calendar.categories.include?(part)
          @calendar_category = part
        elsif Calendar.slugs.include?(part)
          @calendar_slug = part
        else 
          @calendar_parameters.push(part)
        end
      end
      
      if @calendar_year && @calendar_month
        start = Date.civil(@calendar_year.to_i, @calendar_month.to_i)
        @calendar_period = CalendarPeriod.between(start, start.to_datetime.end_of_month)
      elsif calendar_year
        start = Date.civil(@calendar_year.to_i)
        @calendar_period = CalendarPeriod.between(start, start.to_datetime.end_of_year)
      end
      
      logger.warn "!   calendar_period is #{@calendar_period.inspect}"
      logger.warn "!   calendar_year is #{@calendar_year.inspect}"
      logger.warn "!   calendar_month is #{@calendar_month.inspect}"
      
      @calendar_parameters
    end
  end
    
  def calendar_set
    if calendar_category and calendar_slug 
      calendars.in_category(calendar_category).with_slugs(calendar_slug)
    end
  end
  
  def url_parts
    {
      :month => @calendar_month,
      :year => @calendar_year
    }
  end
  
  def url_with_parts(overrides={})
    parts = url_parts.merge(overrides)
    parts[:month] = month_names[parts[:month]].downcase unless parts[:month].blank? || parts[:month] =~ /[a-zA-Z]/
    clean_url(url_without_parts + parts.values.join('/'))
  end
  alias_method_chain :url, :parts

  def month_names
    @month_names ||= Date::MONTHNAMES.dup
  end
  
  def day_names
    unless @day_names
      @day_names = Date::DAYNAMES.dup
      @day_names.push(@day_names.shift) # Class::Date and ActiveSupport::CoreExtensions::Time::Calculations have different ideas of when is the start of the week. we've gone for the rails standard.
    end
    @day_names
  end


  desc %{
    Renders a trail of breadcrumbs to the current page. On an event calendar page this tag is 
    overridden to show the filters applied to calendar data (including category, slug and date rage) 
    as well as the path to this page.

    *Usage:*

    <pre><code><r:breadcrumbs [separator="separator_string"] [nolinks="true"] /></code></pre>
  }
  tag 'breadcrumbs' do |tag|
    page = tag.locals.page
    nolinks = (tag.attr['nolinks'] == 'true')
    
    if calendar_category
      crumbs = nolinks ? [page.breadcrumb] : [%{<a href="#{url}">#{tag.render('breadcrumb')}</a>}]
      if calendar_slug
        crumbs << (nolinks ? calendar_category : %{<a href="#{url}/#{calendar_category}">#{calendar_category}</a>})
        crumbs << calendar_slug
      else
        crumbs << calendar_category
      end
    else
     crumbs = [page.breadcrumb]
    end
    page.ancestors.each do |ancestor|
      tag.locals.page = ancestor
      if nolinks
        crumbs.unshift tag.render('breadcrumb')
      else
        crumbs.unshift %{<a href="#{tag.render('url')}">#{tag.render('breadcrumb')}</a>}
      end
    end
    separator = tag.attr['separator'] || ' &gt; '
    crumbs.join(separator)
  end

end

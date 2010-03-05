require 'rack/utils'

class EventCalendarPage < Page
  include WillPaginate::ViewHelpers

  attr_reader :filters, :calendar_parameters, :calendar_filters, :calendar_year, :calendar_month, :calendar_page, :calendar_category, :calendar_slug, :calendar_period

  description %{ Create a series of calendar pages. }

  def self.sphinx_indexes
    []
  end

  def cache?
    true
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
    if path.blank?
      @calendar_parameters = []
    else
      parts = path.split(/\/+/)
      @calendar_page = parts.shift if parts.last =~ /^\d{1,3}$/
      @calendar_year = parts.find{|p| p =~ /^\d\d\d\d$/}
      if month = parts.find{|p| Date::MONTHNAMES.include?(p.titlecase) }
        @calendar_month = Date::MONTHNAMES.index(month.titlecase)
      end
      @calendar_category = parts.find{|p| Calendar.categories.include?(p) }
      @calendar_slug = parts.find{|p| Calendar.slugs.include?(p) }
      @calendar_period = if @calendar_year && @calendar_month
        start = Date.civil(@calendar_year.to_i, @calendar_month.to_i)
        CalendarPeriod.between(start, start.end_of_month)
      elsif @calendar_year
        start = Date.civil(@calendar_year.to_i)
        CalendarPeriod.between(start, start.end_of_year)
      end
      @calendar_parameters = parts
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
    parts[:month] = month_names[parts[:month]].downcase if parts[:month] && defined? month_names[parts[:month]]
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
    overridden to show the category and slug of the calendar chosen as well as the path to this page.

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

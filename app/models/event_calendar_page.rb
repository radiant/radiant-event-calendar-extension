require 'rack/utils'

class EventCalendarPage < Page
  include WillPaginate::ViewHelpers

  attr_writer :filters, :calendar_parameters, :calendar_filters, :calendar_year, :calendar_month, :calendar_category, :calendar_slug

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
      @filters = $1.split('/')
      self
    else
      super
    end
  end
  
  def calendar_parameters
    logger.warn "!!  filters: #{@filters}"
    @filters ||= []
  end
  
  def calendar_year
    @calendar_year ||= calendar_parameters.find{|p| p =~ /^\d\d\d\d$/}
  end
  
  def calendar_month
    unless @calendar_month
      if month = calendar_parameters.find{|p| Date::MONTHNAMES.include?(p.titlecase) }
        @calendar_month = Date::MONTHNAMES.index(month.titlecase)
      end
    end
  end
  
  def calendar_filters
    @calendar_filters ||= calendar_parameters - [calendar_year, calendar_month]
  end

  def calendar_category
    @calendar_category ||= calendar_filters.find{|p| Calendar.categories.include?(p) }
  end

  def calendar_slug
    @calendar_slug ||= calendar_filters.find{|p| Calendar.slugs.include?(p) }
  end
  
  def calendar_period
    logger.warn "EventCalendarPage looking for period with #{calendar_year}, #{calendar_month}"
    if calendar_year && calendar_month
      CalendarPeriod.new(Date.civil(calendar_year.to_i, calendar_month.to_i, 1), 1.month - 1.day)
    elsif calendar_year
      CalendarPeriod.new(Date.civil(calendar_year.to_i, 1, 1), 1.year - 1.day)
    end
  end
  
  def calendar_set
    if calendar_category and calendar_slug 
      calendars.in_category(calendar_category).with_slugs(calendar_slug)
    end
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

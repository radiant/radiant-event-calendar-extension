require 'rack/utils'

class EventCalendarPage < Page

  description %{ Create a series of calendar pages. }

  def self.sphinx_indexes
    []
  end

  def cache?
    true
  end

  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    if (url =~ %r{^#{ self.url }}) && (not live or published?)
      self
    else
      super
    end
  end
  
  def date_parameters
    @request.path_parameters[:url].select{|p| p !~ /\w/}
  end
  
  def selection_parameters
    @request.path_parameters[:url].select{|p| p !~ /\W/}
  end

  def calendar_category
    selection_parameters[1]
  end
  
  def calendar_slug
    selection_parameters[2]
  end
  
  def calendar_year
    date_parameters[1]
  end
  
  def calendar_month
    date_parameters[2]
  end
  
  def selected_events
    if selection_parameters.any?
      events = EventOccurrence.in_calendars(calendars)
    else
      events = EventOccurrence.all
    end
    if calendar_year && calendar_month
      events = events.in_month(calendar_year, calendar_month)
    elsif calendar_year
      events = events.in_year(calendar_year, calendar_month)
    end
  end
  
  def selected_calendars
    if category = calendar_category
      selection = Calendar.in_category(category)
      if slug = calendar_slug
        selection = selection.with_slugs(slug) unless slug.blank? || slug == 'all'
      end
      selection.find(:all)
    else
      Calendar.all
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

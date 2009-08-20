require 'rack/utils'

class EventCalendarPage < Page

  description %{ Create a series of calendar pages. }

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
  
  # we ought to be munching date parameters (eg from, since) into Date objects

  def calendar_category
    @request.path_parameters[:url][1]
  end
  
  def calendar_slug
    @request.path_parameters[:url][2]
  end
  
  def get_calendars
    if category = calendar_category
      selection = Calendar.in_category(category)
      if slug = calendar_slug
        selection = selection.with_slugs(slug) unless slug.blank? || slug == 'all'
      end
      selection.find(:all)
    else
      Calendar.find(:all)
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

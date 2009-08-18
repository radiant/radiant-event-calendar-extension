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
  
end

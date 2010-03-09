# This handy simplification is adapted from SphinxSearch (thanks)
# and originally came from Ultrasphinx
# it saves us a lot of including and bodging to make will_paginate's template calls work in the Page model

class PaginationLinkRenderer < WillPaginate::LinkRenderer
  def initialize(tag)
    @tag = tag
  end

  def page_link(page, text, attributes = {})
    linkclass = %{ class="#{attributes[:class]}"} if attributes[:class]
    linkrel = %{ rel="#{attributes[:rel]}"} if attributes[:rel]
    %Q{<a href="#{@tag.locals.page.url(:page => page)}"#{linkrel}#{linkclass}>#{text}</a>}
  end

  def page_span(page, text, attributes = {})
    spanclass = attributes[:class]
    %{<span class="#{attributes[:class]}">#{text}</span>}
  end
end

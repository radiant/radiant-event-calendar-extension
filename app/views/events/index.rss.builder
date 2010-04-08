xml = Builder::XmlMarkup.new
xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title Radiant::Config['event_calendar.feed_title'] || "#{Radiant::Config['admin.title']} Events"
    xml.description list_description
    xml.link calendar_url(calendar_parameters.merge(:format => :html))

    events.each do |event|
      xml.item do
        xml.title event.title
        xml.link event.url
        xml.description event.description_paragraph
        xml.pubDate event.created_at.to_s(:rfc822)
        xml.guid event.uuid, :isPermaLink => false
      end

    end
  end
end

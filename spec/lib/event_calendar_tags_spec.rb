require File.dirname(__FILE__) + '/../spec_helper'

describe EventCalendarTags do
  dataset :calendar_pages, :calendar_events
  let(:page) { pages(:calendar) }
  let(:event) { events(:simple) }
  let(:fbe) { events(:facebooked) }
    
  context "rendering event: tags" do
    before do
      Radiant.config['site.host'] = "test.host"
    end
    
    [:id, :title, :description, :short_description, :location, :url, :facebook_id, :facebook_url].each do |tag|
      it "event:#{tag}" do
        page.should render(%{<r:event id="#{event.id}"><r:event:#{tag} /></r:event>}).as( event.send(tag.to_sym).to_s )
      end
    end
    
    it "event:ical_link" do
      page.should render(%{<r:event id="#{event.id}"><r:event:ical_link class="ical">I</r:event:ical_link></r:event>}).as( 
        %{<a href="/cal/events/#{event.id}.ics" title="Download event" class="ical">I</a>} 
      )
    end

    it "event:facebook_link" do
      page.should render(%{<r:event id="#{fbe.id}"><r:event:facebook_link class="fb">F</r:event:facebook_link></r:event>}).as( 
        %{<a href="http://www.facebook.com/event.php?eid=#{fbe.facebook_id}" title="view on facebook" class="fb">F</a>} 
      )
      page.should render(%{<r:event id="#{event.id}"><r:event:facebook_link class="fb">F</r:event:facebook_link></r:event>}).as( "" )
    end
    
    it "event:tweet_link" do
      page.should render(%{<r:event id="#{event.id}"><r:event:tweet_link class="twit" text="foo: & bar" via="me" related="they">T</r:event:tweet_link></r:event>}).as( 
        %{<a href="https://twitter.com/intent/tweet?url=http://test.host/calendar/%23event_#{event.id}&amp;text=foo:%20&%20bar&amp;via=me&amp;related=they" title="Tweet this" class="twit">T</a>} 
      )
    end
  end
  
end
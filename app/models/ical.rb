require 'rubygems' 
require 'net/http'
require 'vpim'
require 'date'

class Ical < ActiveRecord::Base
  belongs_to :calendar
  validates_presence_of :ical_url

  @@calendars_path = Radiant::Config["event_calendar.icals_path"]
  
	# Download and save the .ics calendar file, parse and save events to database
	def refresh
    ical_filename = RAILS_ROOT + "/public/" + @@calendars_path + "/" + self.calendar.slug + ".ics"

    # Retrieve calendar specified by URL and Name attributes
    begin
      uri = URI.parse(ical_url)
      if authenticated?
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path)
        req.basic_auth ical_username, ical_password
        response = http.request(req)
      else
        response = Net::HTTP.get_response(uri)
      end
    	File.open(ical_filename, "w") { |file|
        file << response.body
      }
    rescue 
      logger.error "iCal url or file error with: #{self.calendar.name} - #{ical_url} -> (#{ical_filename}) -- error."
      return false
    end 
    
    # If you were to extend this to mix in manually created event with events received from iCal subscriptions 
    # you'd need to add an Event attribute to indicate which events came from a subscription and only delete those here.
    self.calendar.events.delete_all

    # Open file for reading, parse and store to DB
      File.open(ical_filename, "r") do |file|
        cal = Vpim::Icalendar.decode(file).first
        event_count = 0
        cal.events.each do |parsed_event|
          parsed_event.occurences.each do |o|
            new_event = Event.new
            new_event.start_date = o
            new_event.end_date = Time.local(o.year, o.month, o.day, parsed_event.dtend.hour, parsed_event.dtend.min)
            new_event.title = parsed_event.summary
            new_event.description = parsed_event.description
            new_event.location = parsed_event.location
            new_event.url = parsed_event.url
            new_event.calendar = self.calendar
            new_event.save
            event_count = event_count + 1
          end
        end  
        self.last_refresh_count = event_count
        self.last_refresh_date = Time.now.utc
        self.save
        logger.info self.calendar.category + "/" + self.calendar.name + " - iCalendar subscription refreshed on " + Time.now.strftime("%m/%d at %H:%M")
      end 
	end
	
	def ics_path
	  File.join @@calendars_path, self.calendar.category
  end
  
  def ics_file
	  "#{self.calendar.name}.ics"
  end
	
	def refresh_automatically?
	  ical_refresh_interval.nil? || ical_refresh_interval.to_i != 0
  end
	
	def refresh_interval_or_default
	  (ical_refresh_interval || Radiant::Config['event_calendar.default_refresh_interval'] || 3600).to_i.seconds
  end
  
  def needs_refreshment?
    last_refresh_date.nil? || Time.now > last_refresh_date + refresh_interval_or_default.to_i.seconds
  end
	
	def self.check_refreshments
  	find(:all).each do |i|
  	  i.refresh if i.refresh_automatically? && i.needs_refreshment?
  	end
  end
	
	def self.refresh_all
  	find(:all).each do |i|
  	  i.refresh 
  	end
  	return true
	end
	
	protected
	
  	def authenticated?
  	  not ical_username.blank?
    end
		
		def secured?
  	  ical_url.match(/^https/)
    end
  	
end
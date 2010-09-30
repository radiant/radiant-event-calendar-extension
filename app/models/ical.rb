require 'rubygems' 
require 'net/http'
require 'ri_cal'
require 'date'
require 'ftools'

class Ical < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  belongs_to :calendar
  validates_presence_of :url
  has_site if respond_to? :has_site

  @@calendars_path = Radiant::Config["event_calendar.icals_path"]
  
  def refresh
    retrieve_file
    updated = parse_file
    logger.info self.calendar.category + "/" + self.calendar.name + " - iCalendar subscription refreshed on " + Time.now.strftime("%m/%d at %H:%M")
    updated
  end

  def retrieve_file
    File.makedirs filepath
    begin
      uri = URI.parse(url)
      if authenticated?
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path)
        req.basic_auth username, password
        response = http.request(req)
      else
        response = Net::HTTP.get_response(uri)
      end
      File.open(filename, "w") do |file|
        file << response.body
      end
    rescue => error
      logger.error "iCal url or file error with: #{self.calendar.name} - #{url} -> (#{filename}): #{error}."
      raise
    end
  end

  def parse_file(thisfile=filename)
    affected = []
    begin
      Ical.transaction do
        self.last_refresh_count = 0
        count = { :created => 0, :updated => 0, :deleted => 0 }
        uuids_seen = []
        File.open(thisfile, "r") do |file|
          components = RiCal.parse(file)
          cal = components.first
          cal.events.each do |cal_event|
            if event = Event.find_by_uuid(cal_event.uid)
              if cal_event.dtstamp > event.updated_at
                affected.push event.update_from(cal_event) 
                count[:updated] += 1
              else
              end
            else
              event = Event.create_from(cal_event)
              event.site = self.calendar.site if event.respond_to? :site=
              self.calendar.events << event
              event.save!
              count[:created] += 1
            end
            uuids_seen.push(cal_event.uid)
          end
        end
        self.last_refresh_count = uuids_seen.length
        self.last_refresh_date = Time.now.utc
        self.save!
        
        self.calendar.events.except_these(uuids_seen).each do |event| 
          event.destroy 
          count[:deleted] += 1
        end
        response = [:created, :updated, :deleted].collect { |counter| 
          "#{pluralize(count[counter], 'event')} #{counter}. "
        }.join('')
      end
    rescue => error
      logger.error "RiCal parse error with: #{self.calendar.name}: #{error}."
      raise
    end 
  end
  
  def filepath
    File.join RAILS_ROOT, "public", ics_path
  end
  
  def filename
    File.join filepath, ics_file
  end

  def ics_path
    File.join @@calendars_path, self.calendar.category
  end
  
  def ics_file
    "#{self.calendar.slug}.ics"
  end
  
  def to_ics
    File.join "", ics_path, ics_file
  end

  # I've changed this to make the ical refresh decision a simple yes or no
  # and to make the refresh interval a global value
  def refresh_interval
    (Radiant::Config['event_calendar.refresh_interval'] || 3600).to_i.seconds
  end
  
  def refresh_automatically?
    refresh_interval.nil? || refresh_interval.to_i != 0
  end
    
  def needs_refreshment?
    last_refresh_date.nil? || Time.now > last_refresh_date + refresh_interval
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
      !username.blank?
    end
    
    def secured?
      url.match(/^https/)
    end
    
end
# Event Calendar (iCal) Extension for Radiant

This extension lets your radiant site present calendar data. It doesn't administer calendars or let you enter events: you have a perfectly good desktop calendar application for that. All we do here is subscribe to a calendar feed and publish the contents nicely. The feed can come from Google Calendar, from a published ical file or from any CalDAV-compatible calendar server.

## Recent changes

* The radius tag structure has changed. Those few people who have old event_calendar pages will need to tweak them to use the new `r:calendar` and `r:event` namespaces, of which more below.
* column names have been simplified now that the ical can be dealt with as a nested model
* standard ownership columns have been added to calendar 
* tested with google calendar

## Requirements

You need the `vpim` gem to handle event data:

	gem install vpim

and while any radiant version from 0.6 onwards ought to work, I've only tested this release properly with radiant 0.8.0.

## Installation

Should be straightforward:

	script/extension install event_calendar
	rake radiant:extensions:event_calendar:migrate
	rake radiant:extensions:event_calendar:update
	
event_calendar is multi-site aware and if used with spanner's fork, will scope calendars to sites.

## Configuration

There are only two config settings at the moment:

* `event_calendar.icals_path` is the directory (under /public/) holding the calendar subscription files. Default is `icals`.
* `event_calendar.default_refresh_interval` is the period, in seconds, after which the calendar subscriptions are refreshed. Default is one hour. Set to zero to refresh only in the admin interface. 

Each calendar subscription will have its own address and authentication settings.

## Usage

1. Create a calendar source, either by publishing a feed from your desktop calendar application or by setting up a CalDAV calendar and persuading all the right people to subscribe to it.
2. Find the subscription address of your calendar.
3. Choose 'new calendar' in the radiant admin menu and enter the address and any authentication information you need to get at it. See below for notes about connecting to CalDAV. In the case of an ical file you should only need an address. Give the calendar a slug, just as you would for a page, and optionally a category. Let's say you call it 'test'.
4. Your calendar should appear in the subscription list. Click through to browse its events and make sure everything is as it should be.
5. Set up a new page at /calendar/ with the type 'EventCalendar' and fill it with something this:

	<div class="event_list">
	  <r:events:each year="now">
	    <r:event:header name="date">
	      <h2 id="<r:event:year />_<r:event:month />"><r:event:month /> <r:event:year /></h2>
	    </r:event:header>
		<p id="event_<r:event:id />">
		  <acronym class="date">
		    <r:event:day_ordinal />
		  </acronym>
		  <r:event:link class="title" />
		  <r:event:if_location>
		    <span class="location"><r:event:location /></span>
		  </r:event:if_location>
		  <r:event:if_description>
		    <br />
		    <span class="description"><r:event:description /></span>
		  </r:event:if_description>
		</p>
	  </r:events:each>
	</div>	

Point your browser at /calendar/test and you should see a list of this year's events in that calendar.

Note that the `event:header` tag only shows when it changes, which in this case gives you a non-repeating date slip. For more about the available radius tags, see the extension wiki or the 'available tags' documentation.

If you have another column in your layout, try adding this:

	<r:events:as_calendar calendar_months="6" date_links="true" month_links="false" />

For clickable thumbnails of coming months.

## Notes

This is developing quite quickly at the moment but it's in production use on a couple of small sites and seems stable enough.

### Compatibility

I've tested this with Darwin Calendar Server (on Ubuntu), with Google Calendar and with feeds published from iCal on a mac. It work just as well with iCal server on OS X Server, and in theory any other CalDav-compliant back end. See http://caldav.calconnect.org/ for more possibilities.

### Connecting to CalDAV

We aren't really doing CalDAV properly here, but taking advantage of a compatibility with the simpler ical standard. A simple GET to addresses under /calendar will return a file in ical format, which is what we get and parse. As a passive display client, that's all we need, but it does mean that so far we can't display groups properly, or interact principals, or take proper advantage of the more collaborative functions of CalDAV.

The address for your calendar will either look like this:

	https://[calendar.server.com]:8443/calendars/users/[someone]/calendar/
	
or like this:

	https://[calendar.server.com]:8443/calendars/users/[someone]/1D09F977-2F27-4E87-954D-FFED95A70BC0/

but note that the port and protocol will depend on your server setup. The best way to find these addresses is to visit the calendar server in a normal web browser, log in as the authorised person, and cut and paste the address of the calendar you want. You may also be able to get the right address out of iCal or sunbird but some trial and error will be involved.

The best way to think of these addresses under /calendar/ is as the read-only version. The address that you will subscribe to in your desktop calendar application is the read-write version and will look slightly different:

	https://[calendar.server.com]:8443/principals/users/[someone]/

is all you need to put into iCal, for example: it will handle subcalendars and GUIDs without bothering you for details.

### Setting up a CalDAV server

It's not nice. There are three main options:

* OS X Server has an excellent built-in ICal server
* [Darwin Calendar Server](https://trac.calendarserver.org/wiki) is the open-source version of that. It's written mostly in Python and distinctly quirky, but once set up it works very well.
* Get a Google calendar instead.
* er
* That's it unless you speak Java, in which case there are [several](http://caldav.calconnect.org/implementations/servers.html) other [good options](http://www.bedework.org/bedework/).

See [http://caldav.calconnect.org/](http://caldav.calconnect.org/) for news and background information.

### Quirks

Calendars are only refreshed if they're accessed. The `event_calendar.default_refresh_interval` setting is really a cache-duration setting: on the next request after that interval, we go back to the original source. If that gets too slow for the end user who triggers the refresh then I'll need to add a calendar-refresh rake task that can be crontabbed, but so far it seems to work well enough.

If you're administering your calendars in iCal, the first calendar you set up will be accessible at the simple /users/uid/calendar address but after that you'll have to get the GUIDs. You can get-info on a calendar to get a subscription address but if it's long it may be truncated.

OS X 10.6 promises to handle all this a lot better. On Windows you're pretty much confined to Sunbird at the moment. There is a project to [hook Outlook up](http://openconnector.org/) to CalDAV but it seems to have stalled.

## Bugs and features

Reports and requests in [lighthouse](http://spanner.lighthouseapp.com/projects/26912-radiant-extensions), please, or for little things an email or github message is fine.

## Author & Copyright

Originally created by Loren Johnson: see www.hellovenado.com

Currently maintained by spanner. Contact William Ross <will at spanner.org>.

Released under the same terms as Radiant and/or Rails.





# Event Calendar Extension for Radiant

This extension lets your radiant site present calendar events in various useful ways. The events can be administered directly or retrieved by subscription to ical and caldav services including Google Calendar, and can be served as RSS, Ical or JSON feeds as well as through a broad set of radius tags on your normal pages. This extension supports a wide range of uses from a single-tag display of forthcoming events through to a full calendar aggregation and mapping service.

The calendaring functionality comes from [ri_cal](http://github.com/rubyredrick/ri_cal) and supports proper recurrence and duration. We also recognise all-day events and pass through notes and urls: the ical subscription and redistribution should be fully RFC2445 compliant. It is not yet a full CalDAV client, and we don't have proper support for principals, groups or availability. 

See the [event_map](http://github.com/spanner/radiant-event_map-extension) extension for googlemapping of events and [taggable_events](http://github.com/spanner/radiant-taggable_events-extension) for more fine-grained tagging and retrieval options. A `reader_events` extension is also in the works for public submission of calendar events.

## Requirements

Radiant 0.9 or 1, `layouts` or `share_layouts` and the `ri_cal` gem to handle iCal data. It's declared in the extension so this should do it:

	sudo rake gems:install
	
This is compatible with `multi_site` and with the [sites](http://github.com/spanner/radiant-sites-extension) extension. With the latter everything will be site-scoped.

There is a 0.81 tag in the repository for the last version good with radiant 0.8.1 and `scoped_admin`.

This version includes some optional experiments in dashboard integration. If you're using dashboard you need the spanner fork.

## Installation

Should be straightforward:

	script/extension install event_calendar

or as a gem:

	sudo gem install radiant-event_calendar-extension

with this in your environment.rb:

	config.gem 'radiant-event_calendar-extension', :lib => false

## Configuration

There are a few optional config settings:

* `event_calendar.path` is the stem of all EventsController addresses. It defaults to `/calendar`, which gives you addresses like `/calendar/2011/June`. You can change the stem to any value you like provided it is not also a page address.
* `event_calendar.layout` is the name of the layout that EventsController will use (see below)
* `event_calendar.icals_path` is the directory (under /public/) holding the calendar subscription files. Default is `icals`.
* `event_calendar.refresh_interval` is the period, in seconds, after which the calendar subscriptions are refreshed. Default is one hour. Set to zero to refresh only in the admin interface.
* `event_calendar.cached?` determines whether the EventsController pages are cached by Rack::Cache. EventCalendarPages are always cached like other pages.
* `event_calendar.cache_duration` determines for how long.

Each calendar subscription will have its own address and authentication settings.

## Usage

### Subscribing to a calendar

1. Create a calendar source. You can do that by publishing a feed from your desktop calendar application, by making a google calendar public or by setting up a CalDAV calendar and persuading all the right people to subscribe to it.
2. Find the ical subscription address of your calendar.
3. Choose 'new calendar' in the radiant admin menu and enter the address and any authentication information you need to get at it. See below for notes about connecting to CalDAV. In the case of an ical file or google calendar you should only need an address. Give the calendar a slug, just as you would for a page, and optionally a category. Let's say you call it 'test'.
4. Your calendar should appear in the subscription list. Click through to browse its events and make sure everything is as it should be.

### Adding events manually

Should be obvious. There are a few points to remember:

* Event venues are expected to be reused, so they present as a list with the option to add a new one. 
* The postcode field is a convenience for geocoding purposes. You can leave it blank unless you're mapping and your locations are a bit odd.
* Recurrence is for the repetition of identical separate events. A single event that spans several days only needs to have the right start and end times.
* End times are optional: an event with just a start time is just listed where it begins.

### Displaying events with the EventsController

The events controller uses `share_layouts` to define various page parts that your layout can bring in. To use it, create a layout with any or all of these parts:

* `title` is the page title and can also be shown with `r:title`
* `events` is a formatted list of events with date stamps and descriptions
* `continuing_events` is a compact list of events that have already begun but which continue into the period being shown
* `calendar` is a usual calendar block with links to months and days. Days without events are not linked.
* `pagination` is the usual will_paginate block.
* `faceting` here only gives the option to remove any date filters that have been applied. If you add the `taggable_events` extension it gets more useful.

Set the config entry `event_calendar.layout` to the name of your layout and point a browser at /calendar to see what you've got. 

Here's a basic sample layout that should just work:

	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

	<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
	  <head>
	    <title><r:title /></title>
		<link rel="stylesheet" href="/stylesheets/event_calendar.css" />
	  </head>
	  <body>
        <h1 id="pagetitle"><r:title /></h1>
		<r:content part="faceting" />
        <r:content part="calendar" />
        <r:content part="events" />
        <r:content part="continuing_events" />
		<r:content part="pagination" />
	  </body>
	</html>

One quirk that might go away: at the moment if there are few new events then the continuing events are moved into the events page part. Most layouts work better that way.

### Displaying events with an EventCalendar page

Set up a new page at /events/ with the type 'EventCalendar'. To show a pageable calendar view of the current month, all you need is this:

	<r:events:as_calendar month="now" month_links="true" />
	
Or to show a list of all events in the next six months:

	<p><r:calendars:summary /></p>
	
	<div class="event_list">
	  <r:events:each calendar_months="6">
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

Note that the `event:header` tag only shows when it changes, which in this case gives you a non-repeating date slip. For more about the available radius tags, see the extension wiki or the 'available tags' documentation.

If you have another column in your layout, try adding this:

	<r:events:as_calendar calendar_months="6" date_links="true" compact="true" />

For clickable thumbnails of coming months.

### Compatibility

I've tested this with Darwin Calendar Server (on Ubuntu), with Google Calendar and with feeds published from iCal on a mac. It should work just as well with iCal server on OS X Server, and in theory any other CalDav-compliant back end. See http://caldav.calconnect.org/ for more possibilities.

It should in theory be possible to display a feed from facebook, but I haven't tried it. The 'export events' url is supposed to give an ical-compatible feed that is updated each time you accept or decline an invitation.

### Connecting to Google Calendar

Create a calendar in your Google Calendar account. Call it 'public', or whatever you like, and tick the box marked 'make this calendar public'.

Click on 'calendar settings' from the drop-down menu next to the name of the public calendar, and look towards the bottom for the 'Calendar Address' section. Click on 'ical' and the address that pops up is your subscription address. You shouldn't need anything else.

### Connecting to CalDAV

We aren't really doing CalDAV properly here, but taking advantage of its compatibility with the simpler ical standard. A simple GET to addresses under /calendar will return a file in ical format, which is what we get and parse. As a passive display client, that's all we need, but it does mean that so far we can't display groups properly, or interact with principals, or take proper advantage of the more collaborative functions of CalDAV.

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
* Use a Google calendar and endure a bit of sync bother to get it on the desktop.
* er
* That's it unless you speak Java, in which case there are [several](http://caldav.calconnect.org/implementations/servers.html) other [good options](http://www.bedework.org/bedework/).

See [http://caldav.calconnect.org/](http://caldav.calconnect.org/) for news and background information.

### Quirks

Calendars are only refreshed if they're accessed. The `event_calendar.default_refresh_interval` setting is really a cache duration: on the next request after that interval, we go back to the original source. If that gets too slow for the end user who triggers the refresh then I'll need to add a calendar-refresh rake task that can be crontabbed, but so far it seems to work well enough.

If you're administering your calendars in iCal, the first calendar you set up will be accessible at the simple /users/uid/calendar address but after that you'll have to get the GUIDs. You can get-info on a calendar to get a subscription address but if it's long it may be truncated.

OS X 10.6 promises to handle all this a lot better. On Windows you're pretty much confined to Sunbird at the moment. There is a project to [hook Outlook up](http://openconnector.org/) to CalDAV but it seems to have stalled.

## Bugs and features

[Github issues](http://github.com/radiant/radiant-event-calendar-extension/issues) please, or for little things an email or github message is fine.

## Author & Copyright

Originally created by Loren Johnson - see www.hellovenado.com - and then taken over by the radiant team. Currently maintained by Will at spanner.org.

Released under the same terms as Radiant and/or Rails.





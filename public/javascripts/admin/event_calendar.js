Toggle.SwapperBehavior = Behavior.create(Toggle.LinkBehavior, {
  initialize: function ($super, options) {
    $super(options);
    this.plan_a = this.toggleWrappers.shift();
    this.plan_b = this.toggleWrappers;
    this.toggle();
  },
  toggle: function() {
    if (this.plan_a.visible()) {
      Toggle.hide(this.plan_a, 'none');
      Toggle.show(this.plan_b, this.effect);
    } else {
      Toggle.hide(this.plan_b, 'none');
      Toggle.show(this.plan_a, this.effect);
    }
  }
});

Toggle.RecurrenceSelect = Behavior.create(Toggle.SelectBehavior, {
  initialize: function($super, options) {
    var options = options || {};
    var optionElements = this.element.select('option');
    this.toggleWrapperIDs = $A();
    this.toggleWrapperIDsFor = {};
    
    optionElements.each(function(optionElement) {
      var eid = 'recurrence_' + optionElement.readAttribute('value');
      var elements = [$(eid)];
      var wrapperIDs = elements.map(function(e) { return Toggle.wrapElement(e); }).invoke('identify');
      this.toggleWrapperIDsFor[optionElement.identify()] = wrapperIDs;
      this.toggleWrapperIDs.push(wrapperIDs);
    }.bind(this));
    this.toggleWrapperIDs = this.toggleWrapperIDs.flatten().uniq();
    
    this.effect = "none";
    this.toggle();
    this.effect = options.effect || Toggle.DefaultEffect;
  },
  toggle: function($super) {
    var combo = this.element;
    var option = $(combo.options[combo.selectedIndex]);
    var wrapperIDs = this.toggleWrapperIDsFor[option.identify()];
    var partitioned = this.toggleWrapperIDs.partition(function(id) { return wrapperIDs.include(id); });
    
    Toggle.hide(partitioned[1], 'none');
    Toggle.show(partitioned[0], this.effect);
  }
});

Toggle.MCE = Behavior.create(Toggle.LinkBehavior, {
  initialize: function($super, options) {
    var elements = Toggle.extractToggleObjects(this.element.readAttribute('rel'));
    this.textarea = elements.shift();
  },
  toggle: function() {
    if (!tinyMCE.get(this.textarea)) {
      tinyMCE.execCommand('mceAddControl', false, this.textarea);
    } else {
      tinyMCE.execCommand('mceRemoveControl', false, this.textarea);
    }
  }
});

// We can't rely on padding-right so hard-code the width of the icon instead

DateInputBehavior.addMethods({
  _isOverWidget: function(event) {
    var positionedOverWidget = null;
    if (Prototype.Browser.IE) {
      var widgetLeft = this.element.cumulativeOffset().left;
      var widgetRight = this.element.cumulativeOffset().left + this.element.getDimensions().width;
      positionedOverWidget = (event.pointerX() >= widgetLeft && event.pointerX() <= widgetRight);
    } else {
      var calendarIconWidth = 40;
      var widgetLeft = this.element.cumulativeOffset().left + this.element.getDimensions().width - calendarIconWidth;
      positionedOverWidget = (event.pointerX() >= widgetLeft);
    }
    return positionedOverWidget;
  }
});

// Override the usual Calendar to add a time-picker if the input field also has class 'time'
// and to tweak the positioning of the calendar

var calendar_displacement = {x: 16, y: 16};

DateInputBehavior.Calendar.addMethods({
  _setDate: function(source) {
    if (source.innerHTML.strip() != '') {
      this.date.setDate(parseInt(source.innerHTML, 10));    // nb. only sets the day of month. 
      $A(this.element.getElementsByClassName('selected')).invoke('removeClassName', 'selected');
      source.parentNode.addClassName('selected');
      if (this.selector.element.hasClassName('time')) {
        this._showTime();
      } else {
        this.selector.setDate(this.date);
      }
    }
  },
  _createTimeChooser : function() {
    this.date_chooser = this.element.select('table.calendar').first();
    var timer = this.element.select('div.clock_control').first() || $div({'class': 'clock_control'});
    this.element.insert(timer);
    timer.clonePosition(this.date_chooser);
    timer.setStyle({position: 'relative', left: 0, top: 0, width: this.date_chooser.getWidth(), height: 'auto'});
    this.time_chooser = new DateInputBehavior.Clock(timer, this);
  },
  _showTime: function () {
    this._createTimeChooser();
    this.date_chooser.hide();
    this.time_chooser.show();
  },
  _hideTime: function () {
    this.time_chooser.hide();
    this.date_chooser.show();
  },
  _setTime: function (h,m) {
    this.date.setHours(h);
    this.date.setMinutes(m);
    this.date.setSeconds(0);
    this.selector.setDate(this.date);
  },
  show: function() {
    DateInputBehavior.Calendar.instances.invoke('hide');
    this.date = this.selector.getDate();
    this.redraw();
    this.element.setStyle({
      'top': this.getVerticalOffset(this.selector.element) + 'px',
      'left': this.getHorizontalOffset(this.selector.element) + 'px',
      'z-index': 10001
    });
    this.element.show();
    this.active = true;
  },
  getVerticalOffset: function(selector){
    var defaultOffset = this.selector.element.cumulativeOffset().top + this.selector.element.getHeight() + 2;
    var height = this.element.getHeight();
    var top = 0;
    if (document.viewport.getHeight() > defaultOffset + height) {
      top = defaultOffset - calendar_displacement.y;
    } else {
      top = (defaultOffset - height - selector.getHeight() - 6 + calendar_displacement.y);
    }
    if (top < document.viewport.getScrollOffsets().top) {
      top = document.viewport.getScrollOffsets().top;
    }
    
    return top;
  },
  getHorizontalOffset: function (element) {
    return element.cumulativeOffset().left + element.getWidth() - calendar_displacement.x;
  }
});

Date.prototype.getPaddedMonth = function() {
  var m = (this.getMonth() + 1).toString();
  return (m.length > 1) ? m : "0" + m;
};

Date.prototype.getPaddedDate = function() {
  var d = this.getDate().toString();
  return (d.length > 1) ? d : "0" + d;
};

Date.prototype.getPaddedHours = function() {
  var m = this.getHours().toString();
  return (m.length > 1) ? m : "0" + m;
};

Date.prototype.getPaddedMinutes = function() {
  var m = this.getMinutes().toString();
  return (m.length > 1) ? m : "0" + m;
};

Date.prototype.getPaddedSeconds = function() {
  var s = this.getSeconds().toString();
  return (s.length > 1) ? s : "0" + s;
};

DateInputBehavior.Clock = Behavior.create({
  initialize: function(calendar) {
    this.calendar = calendar;
    this.date = calendar.date;
    this.redraw();
  },
  redraw: function () {
    this.form = new Element('form', {'class': 'clock'});
    this.element.update(this.form);

    this.h = new Element('input', {'type' : 'text', 'class': 'hours', name: 'hours'}).setValue(this.date.getPaddedHours());
    this.m = new Element('input', {'type' : 'text', 'class': 'minutes', name: 'minutes'}).setValue(this.date.getPaddedMinutes());
    this.button = new Element('input', {'type' : 'button', 'class': 'set_time', name: 'set'}).setValue('set');
    this.cancel = new Element('a', {'href': '#', 'class': 'cancel'}).update('change date');

    this.form.insert(new Element('h4', {'class': 'date'}).update(this.date.getDate() + ' ' + DateInputBehavior.Calendar.MONTHS[this.date.getMonth()].label + ', ' + this.date.getFullYear() + ' at:'));
    this.form.insert(this.h);
    this.form.insert(new Element('span', {'class': 'colon'}).update(':'));
    this.form.insert(this.m);
    this.form.insert(new Element('br'));
    this.form.insert(this.button);
    this.form.insert(new Element('br'));
    this.form.insert(this.cancel);
  },
  onclick: function (event) {
    event.stop();
    if ($(event.target).hasClassName('set_time')) this.submit();
    if ($(event.target).hasClassName('cancel')) this.goback();
  },
  submit: function () {
    this.calendar._setTime(this.h.getValue(), this.m.getValue());
  },
  goback: function () {
    this.calendar._hideTime();
  },
  show: function () {
    this.element.show();
  },
  hide: function () {
    this.element.hide();
  }
});

DateInputBehavior.DEFAULTS = {
  setter: function(date) {
    return  date.getFullYear() + '-' + date.getPaddedMonth() + '-' + date.getPaddedDate() + ' ' + date.getHours() + ':' + date.getPaddedMinutes() + ':' + date.getPaddedSeconds();
  },
  getter: function(value) {
    var p = value.split(/\D+/g);
    if (!p[0]) return null;
    var date = new Date(p[0],p[1]-1,p[2],p[3],p[4],p[5]);
    return date;
  }
};

Event.addBehavior({ 
  "input.toggle": Toggle.CheckboxBehavior,
  "a.swapper" : Toggle.SwapperBehavior({effect : 'appear'}),
  "select.basis" : Toggle.RecurrenceSelect({effect : 'appear'}),
  "a.toggleMCE" : Toggle.MCE
});

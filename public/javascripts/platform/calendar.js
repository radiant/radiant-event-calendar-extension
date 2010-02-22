var default_duration = 60 * 60 * 1000;

var date_picker_options = {
  yearPicker: true,
  timePicker: true,
  dayShort: 3,
  format: 'D d M Y @ h:ia',
  inputOutputFormat: 'Y-m-d H:i:s',
  allowEmpty: true,
  positionOffset: { x: 20, y: -10 }
};

var no_time_options = {
  timePicker: false,
  format: 'D d M Y'
};

var DateControl = new Class({
  initialize: function (starter, ender) {
    if (starter && ender) { 
      this.starter = starter;
      this.ender = ender;
      this.alldayer = $('event_all_day');
      this.alldayer.addEvent('click', this.toggleTimes.bind(this));
      picker_options = (this.alldayer.checked) ? $merge(date_picker_options, no_time_options) : date_picker_options; 
      this.startpicker = new DatePicker(this.starter, $merge(picker_options, { onSelect : this.onSetStart.bind(this) }));
      this.endpicker = new DatePicker(this.ender, $merge(picker_options, { onSelect : this.onSetEnd.bind(this) }));
      this.announcer = $('event_note');
      this.toggleTimes();
    }
  },
  toggleTimes: function (checkbox) {
    if (this.alldayer.checked) {
      this.startpicker.options.timePicker = false;
      this.startpicker.options.format = 'D d M Y';
      this.endpicker.options.timePicker = false;
      this.endpicker.options.format = 'D d M Y';
    } else {
      this.startpicker.options.timePicker = true;
      this.startpicker.options.format = 'D d M Y @ h:ia';
      this.endpicker.options.timePicker = true;
      this.endpicker.options.format = 'D d M Y @ h:ia';
    }
    if (this.startDate()) this.startpicker.showDate(this.startDate());
    if (this.endDate()) this.endpicker.showDate(this.endDate());
  },
  startDate: function () {
    var v = this.starter.get('value');
    if (v && v != "") return this.startpicker.unformat(v, this.startpicker.options.inputOutputFormat);
  },
  setStartDate: function (d) {
		this.startpicker.showDate(d);
  },
  endDate: function () {
    var v = this.ender.get('value');
    if (v && v != "") return this.endpicker.unformat(v, this.endpicker.options.inputOutputFormat);
  },
  setEndDate: function (d) {
		this.endpicker.showDate(d);
  },
  setDefaultEndDate: function (d) {
		this.endpicker.default_date = d;
  },
  onSetEnd: function (new_end_date, old_end_date) {
    if (this.startDate() && (new_end_date < this.startDate())) this.badEnd("Please make the end date and time later than the start.");
    else this.clearWarnings();
  },
  onSetStart: function (new_start_date, old_start_date) {
    var end_date = this.endDate();
    if (end_date) {
      if (old_start_date && end_date > old_start_date) {
        this.setEndDate(new Date(end_date.getTime() + new_start_date.getTime() - old_start_date.getTime()));
      } else if (new_start_date > end_date) {
        this.badStart("Please make the start date and time earlier than the end.");
      } else {
        this.clearWarnings();
      }
    } else {
      this.setDefaultEndDate(new Date(new_start_date.getTime() + default_duration));
    }
  },
  badStart: function (message) {
    this.startpicker.visual.addClass('problematic');
    this.announce(message, true);
  },
  badEnd: function (message) {
    this.endpicker.visual.addClass('problematic');
    this.announce(message, true);
  },
  announce: function (message, error) {
    this.announcer.set('text', message);
    if (error) this.announcer.addClass('problematic');
    this.announcer.fade('in');
  },
  clearWarnings: function () {
    if (this.startpicker.visual) this.startpicker.visual.removeClass('problematic');
    if (this.endpicker.visual) this.endpicker.visual.removeClass('problematic');
    this.announcer.fade('out');
  }
});

var RecurrenceControl = new Class({
  initialize: function (container) {   
    this.container = container;
    this.toggle = container.getElement('input.toggle');
    this.detail = container.getElement('span.recurrence_detail');
    this.interval_block = this.detail.getElement('span.recurrence_interval');
    this.basis_block = this.detail.getElement('span.recurrence_basis');
    this.period_block = this.detail.getElement('span.recurrence_period');
    this.limit_block = this.detail.getElement('span.recurrence_limit');
    this.count_block = this.detail.getElement('span.recurrence_count');

    this.interval_field = this.interval_block.getElement('input');
    if (this.interval_field.get('value') == '') this.interval_field.set('value', '1');
    this.basis_chooser = this.basis_block.getElement('select');
    this.period_chooser = this.period_block.getElement('select');
    this.limit_field = this.limit_block.getElement('input');
    this.count_label = this.count_block.getElement('label');

    this.toggle.addEvent('click', this.showIfRelevant.bindWithEvent(this));
    this.interval_field.addEvent('blur', this.setInterval.bindWithEvent(this));
    this.basis_chooser.addEvent('change', this.chooseBasis.bindWithEvent(this));
    this.limitpicker = new DatePicker(this.limit_field, $merge(date_picker_options, no_time_options, { onSelect : this.checkLimit.bind(this) }));
    
    this.setInterval();
    this.chooseBasis();
    this.showIfRelevant();
  },
  showIfRelevant: function () {
    if (this.toggle.checked) this.show();
    else this.hide();
  },
  setInterval: function () {
    if (this.interval_field.get('value') == 1) {
      this.singularize();
    } else {
      this.pluralize();
    }
  },
  chooseBasis: function () {
    if (this.basis_chooser.get('value') == '') {
      this.count_block.hide();
      this.limit_block.hide();
    } else if (this.basis_chooser.get('value') == 'limit') {
      this.limit_block.showInline();
      this.count_block.hide();
    } else {
      this.limit_block.hide();
      this.count_block.showInline();
    }
  },
  checkLimit: function () {
    
  },
  show: function () {
    this.detail.fade('in');
  },
  hide: function () {
    this.detail.fade('out');
  },
  singularize: function () {
    this.period_chooser.getElements('option').each(function (opt) {
      opt.set('text', opt.get('text').replace(/s$/, ''));
    });
  },
  pluralize: function () {
    this.period_chooser.getElements('option').each(function (opt) {
      opt.set('text', opt.get('text') + 's');
    });
  }
});

var VenueControl = new Class({
  initialize: function (oldvenue, newvenue) {
    this.choosing = oldvenue;
    this.chooser = oldvenue.getElement('select');
    this.adding = newvenue;
    document.getElements('a.newvenue').addEvent('click', this.showAdder.bindWithEvent(this));
    document.getElements('a.oldvenue').addEvent('click', this.showChooser.bindWithEvent(this));
  },
  showAdder: function (e) {
    unevent(e);
    this.choosing.addClass('hidden');
    this.adding.removeClass('hidden');
  },
  showChooser: function (e) {
    unevent(e);
    this.adding.addClass('hidden');
    this.choosing.removeClass('hidden');
  }
});

var d = null;
var r = null;
var v = null;

activations.push(function (scope) {
  d = new DateControl(scope.getElements('#event_start_date'), scope.getElements('#event_end_date'));
  v = new VenueControl(scope.getElements('#venue'), scope.getElements('#new_venue'));
  scope.getElements('p.recurrence').each (function (element) { new RecurrenceControl(element); });
});

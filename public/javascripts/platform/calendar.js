var dateset = null;
var recurrence = null;
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

var period_labels = {
  never : '',
  daily : 'days',
  weekly : 'weeks',
  monthly : 'months',
  yearly : 'years'
};

var DateControl = new Class({
  initialize: function (starter, ender) {
    if (starter && ender) { 
      this.starter = starter;
      this.ender = ender;
      this.startpicker = new DatePicker(this.starter, $merge(date_picker_options, { onSelect : this.onSetStart.bind(this) }));
      this.endpicker = new DatePicker(this.ender, $merge(date_picker_options, { onSelect : this.onSetEnd.bind(this) }));
      this.alldayer = $('all_day');
      this.alldayer.addEvent('click', this.toggleTimes.bind(this));
      this.announcer = $('event_note');
    }
  },
  toggleTimes: function (checkbox) {
    if ($('all_day').checked) {
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
  initialize: function (chooser, detail) {   
    if (chooser && detail) {
      this.chooser = chooser;
      this.detail = detail;
      this.basis_chooser = detail.getElement('select#event_recurrence_basis');
      this.limiter = detail.getElement('span#recurrence_limit');
      this.limit_field = this.limiter.getElement('input');
      this.counter = detail.getElement('span#recurrence_count');
      this.count_label = this.counter.getElement('label');

      this.chooser.addEvent('change', this.showIfRelevant.bindWithEvent(this));
      this.basis_chooser.addEvent('change', this.chooseBasis.bindWithEvent(this));
      this.limitpicker = new DatePicker(this.limit_field, $merge(date_picker_options, no_time_options, { onSelect : this.checkLimit.bind(this) }));

      this.chooseBasis();
      this.showIfRelevant();
    }
  },
  showIfRelevant: function () {
    var selection = this.chooser.get('value');
    this.count_label.set('text', period_labels[selection]);
    if (selection == '' || selection == 'never') this.hide();
    else this.show();
  },
  chooseBasis: function () {
    if (this.basis_chooser.get('value') == 'until') {
      this.limiter.showInline();
      this.counter.hide();
    } else {
      this.limiter.hide();
      this.counter.showInline();
    }
  },
  checkLimit: function () {
    
  },
  show: function () {
    this.detail.fade('in');
  },
  hide: function () {
    this.detail.fade('out');
  }
});

activations.push(function (scope) {
  dateset = new DateControl(scope.getElements('#event_start_date'), scope.getElements('#event_end_date'));
  recurrence = new RecurrenceControl(scope.getElements('#event_recurrence_period'), scope.getElements('#recurrence_detail'));
});

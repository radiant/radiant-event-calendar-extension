Toggle.SwapperBehavior = Behavior.create(Toggle.LinkBehavior, {
  initialize: function ($super, options) {
    $super(options);
    this.plan_a = this.toggleWrappers.shift();
    this.plan_b = this.toggleWrappers;
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

Event.addBehavior({ 
  "input.toggle": Toggle.CheckboxBehavior,
  "a.swapper" : Toggle.SwapperBehavior({effect : 'appear'}),
  "select.basis" : Toggle.RecurrenceSelect({effect : 'appear'}),
  "a.toggleMCE" : Toggle.MCE
});

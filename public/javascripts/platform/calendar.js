activations.push(function (scope) {
  scope.getElements('input.date').each(function (element) { new DatePicker(element, {yearPicker: true, timePicker: true, format: 'd-m-Y @ H:i'}); });
});

// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require rails-ujs
//= require activestorage
//= require turbolinks

//= require popper
//= require bootstrap-sprockets

// https://github.com/ankane/chartkick#chartjs
//= require Chart.bundle
//= require chartkick

//= require_tree .

var applicationHandler = (function() {
  var humanizeDateTimeFields = function() {
    $('.momentize-time-ago').each(function(index, element) {
      var momentTimestamp = moment.unix($(element).data('datetime'));
      var now = moment.utc();
      var timeDelta = momentTimestamp.diff(now);
      var humanized = moment.duration(timeDelta).humanize(true);

      $(element).text(humanized);
    });

    $('.momentize-format').each(function(index, element) {
      var momentTimestamp = moment.unix($(element).data('datetime'));
      // Moment Timezone: http://momentjs.com/timezone/docs/#/using-timezones/guessing-user-timezone/
      var timezone = moment.tz.guess();

      // Format: July 9, 2018 12:15 PM PDT
      var humanized = moment.tz(momentTimestamp, timezone).local().format('LLL z');

      $(element).text(humanized);
    });
  };

  // Public API
  return {
    humanizeDateTimeFields: humanizeDateTimeFields
  };
})();

$(document).on('turbolinks:load', function(){
  applicationHandler.humanizeDateTimeFields();
});

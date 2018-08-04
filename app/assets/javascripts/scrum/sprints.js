// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var ScrumSprint = (function() {

  // Constants
  var IMPORT_ICON_SELECTOR = 'table.sprints a.import-sprint';

  // Module Vars

  // Module Functions
  var initialize = function() {
    initImportHandler();
  };

  // Private Methods
  var initImportHandler = function() {
    $(IMPORT_ICON_SELECTOR).on('ajax:success', updateTableRow)
                           .on('ajax:error', ajaxError);
  };

  var updateTableRow = function(event) {
    // For rails-ujs: https://stackoverflow.com/a/45632235/1093087
    var detail = event.detail;
    var data = detail[0], status = detail[1], xhr = detail[2];

    var $importButton = $(this);
    var $row = $importButton.closest('tr');

    console.log(event, data);
  };

  var ajaxError = function(event) {
    console.error(event);
  }

  // Module Public API
  return {
    init: initialize
  };
})();

$(document).on('turbolinks:load', function(){
  ScrumSprint.init();
});

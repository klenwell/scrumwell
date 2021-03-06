// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var ScrumSprint = (function() {

  // Constants
  var IMPORT_ICON_SELECTOR = 'table.sprints a.import-sprint';
  var TABLE_ROW_FIELDS = [
    'story_points_completed',
    'average_velocity',
    'average_story_size',
    'backlog_story_points',
    'wish_heap_story_points',
    'notes'
  ];

  // Module Vars

  // Module Functions
  var initialize = function() {
    initImportHandler();
  };

  // Private Methods
  var initImportHandler = function() {
    // https://github.com/rails/jquery-ujs/wiki/ajax
    $(IMPORT_ICON_SELECTOR).on('ajax:send', clearTableRow)
                           .on('ajax:success', updateTableRow)
                           .on('ajax:error', restoreTableRow);
  };

  var clearTableRow = function(event) {
    var $importButton = $(this);
    var $row = $importButton.closest('tr');

    $importButton.fadeTo('slow', 0.5);

    $.each(TABLE_ROW_FIELDS, function(i, field) {
      var tdSelector = `td.${field}`;
      var $td = $row.find(tdSelector);
      $td.fadeTo('slow', 0.1);
    });
  };

  var restoreTableRow = function(event) {
    var $importButton = $(this);
    var $row = $importButton.closest('tr');

    $importButton.fadeTo('slow', 1.0, function() { $importButton.css('color', 'red') });

    $.each(TABLE_ROW_FIELDS, function(i, field) {
      var tdSelector = `td.${field}`;
      var $td = $row.find(tdSelector);
      $td.fadeTo('slow', 1);
    });
  }

  var updateTableRow = function(event) {
    // For rails-ujs: https://stackoverflow.com/a/45632235/1093087
    var $importButton = $(this);
    var $row = $importButton.closest('tr');
    var data = event.detail[0], status = event.detail[1], xhr = event.detail[2];

    // The html itself needs to be pulled from the XHR.
    var $html = $(xhr.response);

    // $importButton will get replaced with the row, so we need to grab the new one
    // for any visual effects. Will also need to rebind import event if it needs
    // to be functional.
    var $newButton = $html.find('a.import-sprint');

    $newButton.fadeTo('slow', 1.0, function() { $(this).css('color', 'green') });
    $row.replaceWith($html);
  }

  // Module Public API
  return {
    init: initialize
  };
})();

$(document).on('turbolinks:load', function(){
  ScrumSprint.init();
});

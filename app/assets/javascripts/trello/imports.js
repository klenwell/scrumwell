// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var TrelloImport = (function() {
  // Constants
  const IN_PROGRESS_RELOAD_DELAY = 3000;

  // Module Vars

  // Module Functions
  var initialize = function() {
    initStatusReloader();
  };

  // Private Methods
  var initStatusReloader = function() {
    if ( importIsInProgress() ) {
      showLoadingIcon();
      reloadPageAfterDelay(IN_PROGRESS_RELOAD_DELAY);
    }
  };

  var importIsInProgress = function() {
    var inProgressCount = $('[data-import-status="in-progress"]').length;
    return inProgressCount > 0;
  };

  var reloadPageAfterDelay = function(msDelay) {
    var reloadPage = function() {
      location.reload(true);
    };
    setTimeout(reloadPage, msDelay);
  }

  var showLoadingIcon = function() {
    console.log('TODO: show loading icon');
  }

  // Module Public API
  return {
    init: initialize
  };
})();

$(document).on('turbolinks:load', function(){
  TrelloImport.init();
});

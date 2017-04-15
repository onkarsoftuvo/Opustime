app.factory('lazyload', [
  '$http',
  '$rootScope',
  'lazyloadalt',
  function ($http, $rootScope, lazyloadalt) {
    var obj = { };
    obj.config = function () {
      return {
        scrollButtons: {
          scrollAmount: 'auto', // scroll amount when button pressed
          enable: true // enable scrolling buttons by default
        },
        scrollInertia: 500, // adjust however you want
        axis: 'yx',
        theme: 'dark',
        autoHideScrollbar: true,
        advanced: {
          updateOnContentResize: true
        },
        callbacks: {
          onScroll: function () {
            lazyloadalt.setValue(this.mcs.topPct)
          }
        }
      }
    }
    return obj;
  }
]);
app.factory('lazyloadalt', [
  '$http',
  '$rootScope',
  function ($http, $rootScope) {
    var obj = {};
    obj.setValue = function (value) {
      $rootScope.$apply(function () {
        $rootScope.ScrollPer = value;
      })
    }
    return obj;
  }
]);

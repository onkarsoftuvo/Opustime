app.directive('modalWindow', function ($timeout) {
  return {
    priority: 1,
    link: function (scope, element, attrs) {
      $timeout(function () {
        element.find('[autofocus]').focus();
      });
    }
  };
});

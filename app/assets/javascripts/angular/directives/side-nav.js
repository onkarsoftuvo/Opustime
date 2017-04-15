/*app.directive('sideNav', function( $timeout, $window) {
    return {
        restrict: 'A',
        link: function(scope, element) {
            w = angular.element($window);
             scope.$watch( function( ) {
                
                        var slideli = element.find('li');
                        var slideHeight = element[0].offsetHeight/slideli.length
                        slideli.css('height',slideHeight);
                  
                });
             w.bind('resize load', function () {
                scope.$apply();
            });
        }
    };
  });


*/
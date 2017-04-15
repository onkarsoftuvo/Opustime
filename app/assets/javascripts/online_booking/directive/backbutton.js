angular.module('onlineBooking').directive('backbutton', ['$window', '$state' ,function ($window, $state) {
    return {
      restrict: 'A',
      link: function (scope, elem, attrs ) {
        elem.bind('click', function () {
        	console.log($state)
        	if($state.current.name != 'booking-confirmed'){
          		$window.history.go(-1);
        	}
        	else{
            console.log($window.history);
            $window.history.back();
        	}
        });
      }
    };
  }
]);

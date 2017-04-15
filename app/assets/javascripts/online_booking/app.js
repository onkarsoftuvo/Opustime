var app = angular.module('onlineBooking', [
  'ui.router', 
  'iso-3166-country-codes', 
  '720kb.socialshare', 
  'ui.bootstrap', 
  'ngMap', 
  'pascalprecht.translate',
  'ngMaterial',
  'ngCookies',
]);

app.run(function($state, $rootScope, $location, $mdToast){
	$rootScope.$state = $state;
  $rootScope.range = function(min, max, step){
    step = step || 1;
    var input = [];
    for (var i = min; i <= max; i += step) input.push(i);
    return input;
  };
  var date = new Date();
  var curentYear = date.getFullYear();
  var yearTill = curentYear - 80; 
  $rootScope.yearList = [];
  for(i=curentYear; i > yearTill; i--){
    $rootScope.yearList.push(i)
  }

  $rootScope.showSimpleToast = function (content) {
    $mdToast.show($mdToast.simple().content(content).position('bottom right').hideDelay(5000)
    );
  };
  $rootScope.showErrorToast = function (content) {
    $mdToast.show($mdToast.simple().content(content).theme('error-toast-single').position('bottom right').hideDelay(6000)
    );
  };
  $rootScope.showMultyErrorToast = function (content) {
    $mdToast.show({
      templateUrl: 'assets/online_booking/onlinebooking-toast-template.html',
      hideDelay: 6000,
      position: 'bottom right'
    });
  };
});

app.config(function($stateProvider, $urlRouterProvider, $locationProvider, $animateProvider ) {
  $animateProvider.classNameFilter(/angular-animate/);
  // For any unmatched url, redirect to /state1
  $urlRouterProvider.otherwise("/business");
  // Now set up the states
  $stateProvider
    .state('business', {
    url: "/business",
	  controller: 'OB_BusinessCtrl',
    templateUrl: "/templates/online_booking/step1.html",
	  data : { pageTitle: 'Online Booking | step1'}
    })
    .state('service', {
      url: "/service/:businessId",
	  controller: 'OB_ServiceCtrl',
      templateUrl: "/templates/online_booking/step2.html",
	  data : { pageTitle: 'Online Booking | step2'}
    })
    .state('prectitioner', {
      url: "/prectitioner/:businessId/:serviceId",
	  controller: 'OB_PrectitionerCtrl',
      templateUrl: "/templates/online_booking/step3.html",
	  data : { pageTitle: 'Online Booking | step3'}
    })
    .state('schedule', {
      url: "/schedule/:businessId/:serviceId/:practitionerId",
	  controller: 'OB_ScheduleCtrl',
      templateUrl: "/templates/online_booking/step4.html",
	  data : { pageTitle: 'Online Booking | step4'}
    })
    .state('appointment', {
      url: "/appointment/:date/:endTime",
	  controller: 'OB_appointmentCtrl',
      templateUrl: "/templates/online_booking/step5.html",
	  data : { pageTitle: 'Online Booking | step5'}
    })
    .state('booking-confirmed', {
      url: "/booking-confirmed/:appointmentId",
    controller: 'OB_ConfirmationCtrl',
      templateUrl: "/templates/online_booking/booking-confirmed.html",
    data : { pageTitle: 'Booking-Confirmed'}
    })
    .state('booking-rescheduled', {
      url: "/:reschedule/booking-confirmed/:appointmentId",
      controller: 'OB_ConfirmationCtrl',
      templateUrl: "/templates/online_booking/booking-confirmed.html",
      data : { pageTitle: 'Booking-Confirmed'}
    })

    //cancel and rescheduling
    .state('rescheduling', {
      url: "/rescheduling/:appointmentId",
	     controller: 'OB_reScheduleCtrl',
      templateUrl: "/templates/online_booking/rescheduling.html",
	  data : { pageTitle: 'Rescheduling'}
    })
    .state('cancellation', {
      url: "/cancellation/:appointmentId",
	     controller: 'OB_Cancellation',
      templateUrl: "/templates/online_booking/reasone-cancelling.html",
	     data : { pageTitle: 'Cancel Appointment'}
    })
    
    .state('cancelled', {
      url: "/cancelled/:bus_id",
	  controller: 'OB_Cancellation',
      templateUrl: "/templates/online_booking/booking-cancelled.html",
	  data : { pageTitle: 'Booking-Cancelled'}
    })
    .state('step2-new', {
      url: "/step2-new",
	  controller: 'mainCtrl',
      templateUrl: "/templates/online_booking/step2-new.html",
	  data : { pageTitle: 'step2-new'}
    })
  });

// app.factory('$remember', function() {
//   console.log('Name here: ',name);
//     function fetchValue(name) {
//         var gCookieVal = document.cookie.split("; ");
//         for (var i=0; i < gCookieVal.length; i++)
//         {
//             // a name/value pair (a crumb) is separated by an equal sign
//             var gCrumb = gCookieVal[i].split("=");
//             if (name === gCrumb[0])
//             {
//                 var value = '';
//                 try {
//                     value = angular.fromJson(gCrumb[1]);
//                 } catch(e) {
//                     value = unescape(gCrumb[1]);
//                 }
//                 return value;
//             }
//         }
//         // a cookie with the requested name does not exist
//         return null;
//     }
//     return function(name, values) {
//         if(arguments.length === 1) return fetchValue(name);
//         var cookie = name + '=';
//         if(typeof values === 'object') {
//             var expires = '';
//             cookie += (typeof values.value === 'object') ? angular.toJson(values.value) + ';' : values.value + ';';
//             if(values.expires) {
//                 var date = new Date();
//                 date.setTime( date.getTime() + (values.expires * 24 *60 * 60 * 1000));
//                 expires = date.toGMTString();
//             }
//             cookie += (!values.session) ? 'expires=' + expires + ';' : '';
//             cookie += (values.path) ? 'path=' + values.path + ';' : '';
//             cookie += (values.secure) ? 'secure;' : '';
//         } else {
//             cookie += values + ';';
//         }
//         document.cookie = cookie;
//     }
// });



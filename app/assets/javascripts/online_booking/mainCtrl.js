angular.module('onlineBooking').controller('mainCtrl', function ($scope, $http, $location, $window, $timeout, $q) {
  $scope.myDate = new Date();
});

//Header Ctrl
angular.module('onlineBooking').controller('headerCtrl', headerCtrl)
function headerCtrl($scope, OB_service, $state, $rootScope, $uibModal, $stateParams) {
  function getBookingInfo() {
    OB_service.getBookingInfo().then(function (results) {
      $scope.bookingInfo = results.data;
      $scope.logopath = location.host + results.data.logo
    })
  }
  $scope.googleMapsUrl="https://maps.google.com/maps/api/js?key=AIzaSyAqUu2odiGaaFRirVwsxobAVYRsIMNxQEI&libraries=placeses,visualization,drawing,geometry,places";
  getBookingInfo()  //header buttons
  $scope.showBack = false;
  $scope.showPrint = false;
  $scope.slowLoad = false;
  $rootScope.$on('$stateChangeStart', function (event, toState, toParams, fromState, fromParams) {
    if(toState.name == 'appointment' && fromState.name =='booking-confirmed'){
      //$state.go('business')
      location.href= location.origin+'/booking'
    }
    $scope.showBack = false;
    $scope.showPrint = false;
    if (toState.name != 'business') {
      $scope.showBack = true
    }
    if (toState.name == 'booking-confirmed' || toState.name == 'booking-rescheduled') {
      $scope.showPrint = true;
    }
  })
  $scope.share_url = location.origin + '/booking'
  domain_name = location.origin 
  $scope.share_media= domain_name + '/assets/opus_book.png',
  $scope.GetPdf = function () {
    url = '/appointments/' + $stateParams.appointmentId + '/booking/print.pdf?comp_id=' + localStorage.getItem('comp_id');
    //url = '/appointments/' + $stateParams.appointmentId + '/booking/print.pdf?comp_name=GoChiro Inc.'
    var win = window.open(url, '_blank');
    win.focus();
  }
  $scope.email = function (size) {
    var modalInstance = $uibModal.open({
      animation: true,
      templateUrl: 'emailModal.html',
      controller: 'emailModalCtrl',
      size: size,
    });
    modalInstance.result.then(function (selectedItem) {
      $scope.selected = selectedItem;
    }, function () {
      // $log.info('Modal dismissed at: ' + new Date());
    });
  };
}

angular.module('onlineBooking').controller('emailModalCtrl', function ($scope, $uibModalInstance, OB_service, $stateParams) {
  $scope.other_email = ''
  $scope.sendEmail = function () {
    OB_service.sendEmail($stateParams.appointmentId, {
      other_email: $scope.other_email
    }).then(function (results) {
      if (results.flag) {
        $uibModalInstance.close('closed');
      }
    })
  };
  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});

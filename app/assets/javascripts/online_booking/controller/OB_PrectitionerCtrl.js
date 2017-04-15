angular.module('onlineBooking').controller('OB_PrectitionerCtrl', OB_PrectitionerCtrl)
function OB_PrectitionerCtrl($scope, OB_service, $stateParams, $state) {
  $scope.PractitionersList = [];
  $scope.businessId = $stateParams.businessId;
  $scope.serviceId = $stateParams.serviceId;
  //getting Practitioners list
  function getPractitioners() {
    OB_service.getPractitioners($scope.businessId, $scope.serviceId).then(function (results) {
      if (results.data.practitioner_avails.length == 1) {
        $state.go('schedule', {
          businessId: $scope.businessId,
          serviceId: $scope.serviceId,
          practitionerId: results.data.practitioner_avails[0].id
        })
      }
      if (results.data.practitioner_avails.length > 1){
        $scope.PractitionersList = results.data.practitioner_avails;
      }
    })
  }
  getPractitioners();
}

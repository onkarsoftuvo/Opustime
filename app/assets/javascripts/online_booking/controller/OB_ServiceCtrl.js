angular.module('onlineBooking').controller('OB_ServiceCtrl', OB_ServiceCtrl)
function OB_ServiceCtrl($scope, $stateParams, OB_service, $state) {
  $scope.ServicesList = [];
  $scope.businessId = $stateParams.businessId
  $scope.categoryList = []  
  //getting business list
  $scope.gotoNext = function(sid){
    OB_service.getPractitioners($scope.businessId, sid).then(function (results) {
      if (results.data.practitioner_avails.length == 1) {
        $state.go('schedule', {
          businessId: $scope.businessId,
          serviceId: sid,
          practitionerId: results.data.practitioner_avails[0].id
        })
      }
      if (results.data.practitioner_avails.length > 1){
        $state.go('prectitioner', {
           businessId: $scope.businessId,
           serviceId:sid
        })
      }
    })
    
  }
  function getServicesList() {
    OB_service.getServicesList($scope.businessId).then(function (results) {
      // if (results.data.length == 1) {
      //   $state.go('prectitioner', {
      //     businessId: $scope.businessId,
      //     serviceId: results.data[0].id
      //   })
      // }
      if(results.data.length > 0){
        $scope.ServicesList = results.data;
        getServiceCategory();
      }
    })
  }
  function getServiceCategory() {
    OB_service.getServiceCategories($scope.ServicesList).then(function (results) {
      $scope.categoryList = results;
    })
  }
  getServicesList()
}

angular.module('onlineBooking').controller('OB_BusinessCtrl', OB_BusinessCtrl)
function OB_BusinessCtrl($scope, OB_service, ISO3166, $state, $translate, $rootScope) {
  $scope.BusinessList = [];
  //getting business list
  //OB_service.getCountryById();
  function getBusinessList() {
    OB_service.getBusinessList().then(function (results) {
      if (results.data.locations.length == 1) {
        $state.go('service', {
          businessId: results.data.locations[0].id
        })
      }
      if (results.data.locations.length > 0) {
        results.data.locations.forEach(function (business) {
          var countries = JSON.parse(localStorage.countries);
          var filename = countries.filter(function (c) {
            return c.code === business.country;
          }) [0].filename;
          OB_service.getState(filename, business.state).then(function (results) {
            business.stateName = results
          })
        });
      }
      else {
        $translate('OB.noBusinessLocation').then(function (msg) {
          //$rootScope.showSimpleToast(msg);
          $scope.error = msg;
        });
        //$scope.error = 'There are no businesses/locations enabled for online bookings. This can be done at Settings > Business Information within your Cliniko account.'
      }
      $scope.BusinessList = results.data.locations;
    })
  }
  OB_service.getCountry()
  getBusinessList();
}

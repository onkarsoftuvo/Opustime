angular.module('onlineBooking').controller('OB_ScheduleCtrl', OB_ScheduleCtrl)
function OB_ScheduleCtrl($scope, OB_service, $stateParams, $state) {
  $scope.CalAvailability = [];
  $scope.businessId = $stateParams.businessId
  $scope.servicesId = $stateParams.serviceId;
  $scope.practitionerId = $stateParams.practitionerId;
  localStorage.setItem('OB_businessId', $scope.businessId)
  localStorage.setItem('OB_servicesId', $scope.servicesId)
  localStorage.setItem('OB_practitionerId', $scope.practitionerId)  //getting Calendar Availability list
  $scope.day = moment()
  $scope.selectedMonth = $scope.day;
  $scope.checked //= moment()
  $scope.dayavailability
  console.log($scope.dayavailability);
  $scope.$watch('checked', function () {
    if ($scope.checked != undefined) {
      updateAvailability()
    }
  })
  $scope.$watch('month', function () {
    if ($scope.month != undefined) {
    }
  })
  function updateAvailability() {
    /*OB_service.getDayAvailability($scope.businessId, $scope.practitionerId, $scope.servicesId, $scope.checked).then(function(results){
		$scope.DayAvailability = results
	})*/
  }
  function getMonthAvailability() {
    OB_service.getMonthAvailability($scope.businessId, $scope.practitionerId, $scope.servicesId, $scope.selectedMonth).then(function (results) {
      $scope.MonthAvailability = results;
    })
  }
  $scope.ChooseTime = function (time) {
    var date = angular.copy($scope.checked);
    var startTime = time[0].split(':')
    startTime = date.hour(startTime[0]).minute(startTime[1])
    startTime = startTime.unix()
    $state.go('appointment', {
      date: startTime,
      endTime: time[1]
    })
  }
  getMonthAvailability()
}

angular.module('onlineBooking').controller('OB_reScheduleCtrl', OB_reScheduleCtrl)
function OB_reScheduleCtrl($scope, OB_service, $stateParams, $state) {
  
  var comp_name = location.hash.split('?')[1];

  //getting Calendar Availability list
  function getAppointmentInfo() {
    OB_service.getAppointmentInfo($stateParams.appointmentId).then(function (results) {
      $scope.AppointmentInfo = results.data;
      $scope.businessId = results.data.business_info.id;
      $scope.practitionerId = results.data.doctor_info.id;
      $scope.servicesId = results.data.service_info.id;
      getMonthAvailability();
    })
  }
  getAppointmentInfo();
  
  $scope.CalAvailability = [];
  $scope.selectedTime = '';
  //getting Calendar Availability list
  $scope.day = moment()
  $scope.selectedMonth = $scope.day;
  $scope.checked //= moment()
  $scope.dayavailability
  $scope.$watch('checked', function () {
    if ($scope.checked != undefined) {
    }
  })
  $scope.$watch('month', function () {
    if ($scope.month != undefined) {
    }
  })
  function getMonthAvailability() {
    OB_service.getMonthAvailability($scope.businessId, $scope.practitionerId, $scope.servicesId, $scope.selectedMonth, comp_name).then(function (results) {
      $scope.MonthAvailability = results;
    })
  }
  $scope.ChooseTime = function (time) {
    $scope.selectedTime = time
    var date = angular.copy($scope.checked);
    var startTime = time[0].split(':')
    startTime = date.hour(startTime[0]).minute(startTime[1])
    startTime = startTime.unix()
  }
  $scope.rechedule = function () {
    var data = {}
    var startTime = $scope.selectedTime[0].split(':')
    var endTime = $scope.selectedTime[1].split(':')
    data.id = $stateParams.appointmentId;
    data.start_hr = startTime[0];
    data.start_min = startTime[1];
    data.end_hr = endTime[0];
    data.end_min = endTime[1];
    $scope.checked.hour(data.start_hr).minute(data.start_min)
    data.appnt_date = $scope.checked;
    OB_service.UpdateAppointment({
      appointment: data
    }).then(function (results) {
      $state.go('booking-rescheduled', {
        reschedule: 'rechedule',
        appointmentId: results.data.id
      })
    })
  }
  // getMonthAvailability();
}

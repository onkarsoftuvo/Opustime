angular.module('onlineBooking').controller('OB_Cancellation', OB_Cancellation)
function OB_Cancellation($scope, $stateParams, OB_service, $state, $location) {
  var comp_name = location.hash.split('?')[1];
  var appointmentId = $stateParams.appointmentId;

  $scope.appointment = {
    reason: 'Other'
  };

  $scope.gotoReschedule = function () {
    $state.go('rescheduling', {
      appointmentId: appointmentId
    })
  }
  $scope.cancelAppointment = function (data) {
    OB_service.cancelAppointment({
      appointment: data
    }, appointmentId).then(function (results) {
      if (results.data.flag) {
        $state.go('cancelled', {'bus_id' : results.data.company_id})
      }
    })
  }
  $scope.reCheck = function(){
    var link = location.origin;
    location.href = link +'/booking?comp_id='+$stateParams.bus_id;
  }
}

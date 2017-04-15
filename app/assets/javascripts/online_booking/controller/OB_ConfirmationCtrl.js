var app = angular.module('onlineBooking');

app.controller('OB_ConfirmationCtrl', [
  '$scope',
  'OB_service',
  '$stateParams',
  '$state',
  '$cookies',
  function OB_ConfirmationCtrl($scope, OB_service, $stateParams, $state, $cookies) {
  $scope.getAppointmentInfo = {}
  $scope.appointmentId = $stateParams.appointmentId
  $scope.confirmMsg = 'confirmed'
  if ($stateParams.reschedule != undefined) {
    $scope.confirmMsg = 'rescheduled'
  }  
  //getting Calendar Availability list
  function getAppointmentInfo() {
    OB_service.getAppointmentInfo($scope.appointmentId).then(function (results) {
      $cookies.put('patient_token', results.data.patient_token);
      $scope.AppointmentInfo = results.data
      $scope.share_config = {
        text:'Opus Time online Booking',
        description: 'I have  an appointment with ' + results.data.doctor_info.name + ' at ' + results.data.business_info.full_address + ' on ' + results.data.appnt_date + ' ' + results.data.appnt_at,
        email_description: 'I have  an appointment with ' + results.data.doctor_info.name + ' at ' + results.data.business_info.full_address + ' on ' + results.data.appnt_date + ' ' + results.data.appnt_at + ' \nYou can book at ' +location.origin + '/booking',
        //media: location.origin + '/assets/opus_logo.jpg',
        media: 'http://54.237.219.232/assets/opus_logo.jpg',
        url: location.origin + '/booking'
      }
    })
  }

  $scope.backtoWebsite = function () {
    location = $scope.AppointmentInfo.business_info.web_url
  }
  $scope.getIcal = function () {
    location.href = '/booking/appointments/' + $scope.appointmentId + '/ical/generate.ics'
  }
  $scope.printPage = function () {
    window.print()
  }
  $scope.goToGoogleCal = function () {
    url = '/appointments/' + $scope.appointmentId + '/google/calendar'
    var win = window.open(url, '_blank');
    win.focus();
  }
  getAppointmentInfo();
  }
]);

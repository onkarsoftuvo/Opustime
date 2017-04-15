app.controller('appointmentReminderCtrl', [
  '$rootScope',
  '$scope',
  '$http',
  '$modal',
  '$translate',
  '$state',
  function ($rootScope, $scope, $http, $modal, $translate, $state) {
    //Add appointment
    function GetAppointmentReminder() {
      $http.get('/appointment_reminders').success(function (results) {
        console.log('Here the appointment reminder: ',results);
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.appointmentreminder = results;  
        }
        
      })
    }
    GetAppointmentReminder();
    //update appointment reminder
    $scope.AppointmentReminderSubmit = function (data) {
      // console.log('Here the updated appointment reminder: ', data);
      $http.put('appointment_reminders/' + data.appointment_reminder.id, data).success(function (results) {
        $translate('toast.appTypeReminderUpdated').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        $scope.appointmentreminder = results;
        GetAppointmentReminder();
      })
    }
    //view sample modal
    $scope.viewSample = function (data) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: data,
        controller: 'sampleModal',
        size: 'md',
      });
    };
    $scope.stopEvents = function (events) {
      events.preventDefault();
      events.stopPropagation();
    }
  }
]);
app.controller('sampleModal', [
  '$scope',
  '$modalInstance',
  function ($scope, $modalInstance) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
  }
]);
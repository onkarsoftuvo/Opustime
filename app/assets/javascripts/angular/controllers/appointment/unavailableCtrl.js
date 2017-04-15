/*first appoiment controler*/
app.controller('unavailableBlockCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  'Data',
  'event',
  'uiCalendarConfig',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, Data, event,uiCalendarConfig, $translate) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.appointmentsDetails = {
    };
    $scope.main_btns = true;
    $scope.delete_app_sec = false;
    $scope.delete_app = function () {
      $scope.main_btns = false;
      $scope.delete_app_sec = true;
    }
    $scope.dont_delete = function () {
      $scope.main_btns = true;
      $scope.delete_app_sec = false;
    }
    $scope.rescheduleAppointment=function(data){
      $rootScope.reScheduleData=data;
      $modalInstance.dismiss('cancel');
      $rootScope.reScheduleUnavail=true;
    }
    $scope.anotherAppointment=function(data){
      $modalInstance.dismiss('cancel');
      $rootScope.unavailableActivate=true;
    }
    $scope.getAppointmentsDetails = function (id) {
      $rootScope.cloading = true;
      Data.get('/appointments/vailability/' + id).then(function (results) {
        $scope.appointmentsDetails = results;
        $scope.appointmentsDetails.deleteUnavail = '0';
        $rootScope.cloading = false;
      });
    }
    $scope.getAppointmentsDetails(event);
    
    //edit appointment popup
    $scope.editUnavailbility = function () {
      $modalInstance.dismiss('cancel');
      var modalInstance = $uibModal.open({
        templateUrl: 'unavailBlock.html',
        controller: 'editUnavailBlockCtrl',
        size: 'large_modal',
        resolve: {
          eventData: function () {
            return $scope.appointmentsDetails;
          }
        }
      });
    }

    //delete this one appointment

    $scope.deleteUnavail = function (id, flag) {
      var flagIndication = parseInt(flag);
      $rootScope.cloading = true;
      $http.delete ('/appointments/availability/' + id + '?flag=' + flagIndication).success(function (results) {
        $rootScope.cloading = false;
        if (results.flag) {
          $modalInstance.dismiss('cancel');
          $translate('toast.deleteUnavail').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
      })
    }
  }
]);
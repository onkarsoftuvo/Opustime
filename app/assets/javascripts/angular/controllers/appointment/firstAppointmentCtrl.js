/*first appointment controller*/
app.controller('firstAppoinmentCtrl', [
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
    var currentUser = localStorage.currentUser;
    UserSettings = JSON.parse(localStorage.UserSettings);
    if(UserSettings[currentUser] == undefined){
      UserSettings[currentUser] = {};
    }
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.appointmentsDetails = {};
    $scope.main_btns = true;
    $scope.delete_app_sec = false;
    $scope.cancelAppointment=false;
    $scope.delete_app = function () {
      $scope.main_btns = false;
      $scope.delete_app_sec = true;
    }
    $scope.dont_delete = function () {
      $scope.main_btns = true;
      $scope.delete_app_sec = false;
    }
    $scope.cancelApp=function(){
      $scope.main_btns = false;
      $scope.cancelAppointment=true;
    }
    $scope.dntCancel=function(){
      $scope.main_btns = true;
      $scope.cancelAppointment=false; 
    }
    $scope.rescheduleAppointment=function(data){
      $rootScope.reScheduleData=data;
      $modalInstance.dismiss('cancel');
      $rootScope.reSchedule=true;
    }
    $scope.anotherAppointment=function(data){
      $modalInstance.dismiss('cancel');
      $rootScope.anotherApp=true;
      $rootScope.anotherAppData=data;
    }
    $scope.getAppointmentsDetails = function (id) {
      $rootScope.cloading = true;
      Data.get('/appointments/' + id).then(function (results) {
        $rootScope.patientForTrearmentNote=results.appointment.patient_detail.patient_name;
        $scope.appointmentsDetails = results.appointment;
        $scope.appointmentsDetails.deleteAppointment = '0';
        $rootScope.cloading = false;
      });
    }
    $scope.getAppointmentsDetails(event);
    //add payment
    $scope.addPayment=function(id){
      $modalInstance.dismiss('cancel');
      $state.go('appointment.new_qs', { 'app_id':id});
    }
    //go on invoice show page
    $scope.goInvoice=function(invoice_id){
      $modalInstance.dismiss('cancel');
      $state.go('appointment.invoiceView', { 'invoice_id':invoice_id});
    }
    //go on patient detail page
    $scope.goToPatientPage=function(id){
      $modalInstance.dismiss('cancel');
      $state.go('patient-detail', { 'patient_id':id});
    }
    
    //edit appointment popup
    $scope.editAppointment = function () {
      $modalInstance.dismiss('cancel');
      var modalInstance = $uibModal.open({
        templateUrl: 'editAppointment.html',
        controller: 'editAppointmentCtrl',
        size: 'large_modal',
        resolve: {
          event: function () {
            return $scope.appointmentsDetails;
          }
        }
      });
    }
    // Next appointment
    var addPracti = false;
    var addBuis = false;
    $scope.NextAppoinment=function(appoint_id)
     { 
        $http.get('/appointments/'+appoint_id).success(function (data) {
          var app_detail = data.appointment;
          var StoredBuis = UserSettings[currentUser].savedBusiness;
          if(app_detail.business!=StoredBuis){
            UserSettings[currentUser].savedBusiness = app_detail.business;
            localStorage.UserSettings = JSON.stringify(UserSettings);
          } 
          var StoredDr = UserSettings[currentUser].allDoctors;
          StoredDr = StoredDr.split(',');
          for(i=0;i<StoredDr.length;i++)
          {
            if(app_detail.practitioner_id!=StoredDr[i])
            {
              addPracti = true;
             }
          }
          if(addPracti){
            StoredDr.push(app_detail.practitioner_id);
            UserSettings[currentUser].allDoctors = StoredDr;
            localStorage.UserSettings = JSON.stringify(UserSettings);
          }
            UserSettings[currentUser].savedview = 'agendaThreeDay';
            localStorage.UserSettings = JSON.stringify(UserSettings);
            console.log('calendars: ', uiCalendarConfig);
            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate',app_detail.appnt_date_only);
            $rootScope.bounce = true;
            $rootScope.bounceId=appoint_id;
             $modalInstance.dismiss('cancel');
        });
    }
      
    //SMS popup
    $scope.sendSmsModal = function () {
      $modalInstance.dismiss('cancel');
      var modalInstance = $uibModal.open({
        templateUrl: 'sendSmsModal.html',
        controller: 'sendSmsModalCtrl',
        size: 'md'
      });
    }

    $scope.TreatmentPopup = function (id, app_id) {
      $scope.treatmentData = {};
      $scope.treatmentData.patientId = id;
      $scope.treatmentData.appointment_id = app_id;

      $modalInstance.dismiss('cancel');
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'treatmentNote.html',
        controller:'treatmentNoteModuleCtrl',
        size: 'lg modal-large_modal',
        resolve: {
          treatData: function () {
            return $scope.treatmentData;
          }
        }
      });
    };

    $scope.openClientEmail = function(id){
      localStorage.setItem('emailPatient', id);
      $state.go('patient-detail', {patient_id:id});
      $modalInstance.dismiss('cancel');
    }
    //delete this one appointment

    $scope.deleteApp = function (id, flag) {
      var flagIndication = parseInt(flag);
      $rootScope.cloading = true;
      $http.delete ('/appointments/' + id + '?flag=' + flagIndication).success(function (results) {
        $rootScope.cloading = false;
        if (results.flag) {
          $modalInstance.dismiss('cancel');
          $translate('toast.DeleteAppointment').then(function (msg) {
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
    $scope.appCancel={};
    $scope.appCancel.reason="Other";
    $scope.cancelAppWithReason=function(id,data){
      $scope.appointment={};
      $rootScope.cloading=true;
      $scope.appointment={appointment:data};
      $http.put('/appointments/' + id +'/partial/update', $scope.appointment).success(function (data) {
        $rootScope.cloading = false;
        if (data.flag == true) {
          $modalInstance.dismiss('cancel');
          $translate('toast.cancelAppointment').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = data.error;
          $rootScope.showMultyErrorToast();
        }
      });

    }
    //Arrived code
    $scope.Patient_arrived_status = function(id,value,data)
    {
      $scope.appointment = {};
      $scope.appointment.patient_arrive=value;
      $scope.appointment.id=id;
      $scope.appointment.patient_id=data.patient.id;
      $scope.appointment={appointment:$scope.appointment}
         $rootScope.cloading = true;
          $http.put('/appointments/'+id+'/partial/update', $scope.appointment).success(function (data) {
            $rootScope.cloading = false;
            if (data.flag == true) {
             $modalInstance.dismiss('cancel');
             $rootScope.getEvents();
            } 
            else {
              $rootScope.errors = data.error;
              $rootScope.showMultyErrorToast();
            }
          })
    }
      //Complete & pending code
    $scope.Patient_complete_status = function(id,value,data,element)
    {
      $scope.appointment = {};
      $scope.appointment.appnt_status=value;
      $scope.appointment.id=id;
      $scope.appointment.patient_id=data.patient.id;
      if(value==true){
        $scope.appointment.patient_arrive=true;
      }
      $scope.appointment={appointment:$scope.appointment}
         $rootScope.cloading = true;
          $http.put('/appointments/'+id+'/partial/update', $scope.appointment).success(function (data) {
            $rootScope.cloading = false;
            if (data.flag == true) {
             $modalInstance.dismiss('cancel');
             $rootScope.getEvents();
            } 
            else {
              $rootScope.errors = data.error;
              $rootScope.showMultyErrorToast();
            }
          });
    }
  }
]);

/*send SMS controler*/
app.controller('sendSmsModalCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  'Data',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, Data) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }

   }
]);  


/*edit appointment controler*/
app.controller('editAppointmentCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  'Data',
  'event',
  '$timeout',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, Data, event, $timeout, $translate) {
    /*close modal*/
    $scope.appointment={};
    $scope.popUpLoading = false;
    $scope.have_error = false;
    $rootScope.endTimeError=false;
    $scope.notValidPatient = false;
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.dateOptions = {
      formatYear: 'yy',
      maxDate: new Date(2020, 5, 22),
      minDate: new Date(),
      startingDay: 1,
      showWeeks: false,
      showButtonBar: false
    };
    $scope.date = {
      opened: false
    };
    $scope.open = function ($event) {
      $scope.date.opened = true;
    };
    $rootScope.getPatientsData();
    //filter patient list with typehead(replace id with name)
    $scope.formatLabel = function (model) {
      $scope.notValidPatient = false;
      for (var i = 0; i < $rootScope.listLength; i++) {
        if (model === $rootScope.PatientListData[i].id) {
          return $rootScope.PatientListData[i].first_name + ' ' + $rootScope.PatientListData[i].last_name;
        }
      }
    };
    $scope.getDoctersList = function () {
      $http.get('/settings/doctors').success(function (data) {
        $scope.DoctersList = data.practitioners;
      });
    }
    $scope.getDoctersList();

    $scope.selectedEndHour = '';
    $scope.selectedEndMin = '';
    $scope.editAppointment = function () {
      $rootScope.cloading = true;
      $http.get('/appointments/' + event.id + '/edit').success(function (data) {
        $scope.appointment = data.appointment;
        $scope.appointment.appointment_type_id = (data.appointment.appointment_type_info.id).toString();
        $scope.selectedStartHour = $scope.appointment.start_hr;
        $scope.selectedStartMin = $scope.appointment.start_min;
        $scope.selectedEndHour = $scope.appointment.end_hr;
        $scope.selectedEndMin = $scope.appointment.end_min;
        $scope.startTime = $scope.selectedStartHour + ':' + $scope.selectedStartMin;
        $scope.endTime = $scope.selectedEndHour + ':' + $scope.selectedEndMin;
        $scope.weekDay=$scope.appointment.week_days;
        $scope.weekDays={};
        var obj = {};
        for(i=0;i<$scope.appointment.week_days.length;i++){
          var dayNo='day'+$scope.appointment.week_days[i];
          obj[dayNo] = true;
        }
        $scope.weekDays=obj;
        $rootScope.getAppointmentType($scope.appointment.user_id, $scope.appointment.appointment_type_info);
        $scope.appointment.flag = 0;
        if ($scope.appointment.repeat_by == null) {
          $scope.appointment.repeat_by = 'None';
        }
        $rootScope.checkAvailbilityEdit();
      });
    }
    $scope.editAppointment();
    //Check availblity of Practitionar
    $scope.isAvailDocter = false;
    $rootScope.checkAvailbilityEdit = function(){
      var b_id = $rootScope.currentBusiness.id;
      var p_id = $scope.appointment.user_id;
      var app_id = parseInt($scope.appointment.appointment_type_id);
      var start_hr = $scope.appointment.start_hr;
      var start_min = $scope.appointment.start_min;
      var end_hr = $scope.appointment.end_hr;
      var end_min = $scope.appointment.end_min;
      $scope.appointment.appnt_date = new Date($scope.appointment.appnt_date);
      var day = ($scope.appointment.appnt_date).getDate();
      var month = ($scope.appointment.appnt_date).getMonth()+1;
      var year = ($scope.appointment.appnt_date).getFullYear();

      $http.get('/appointments/'+b_id+'/practitioners/'+p_id+'/'+app_id +'/availability?m='+month+'&y='+year+'&d='+day+'&start_hr='+start_hr+'&start_min='+start_min+'&end_hr='+end_hr+'&end_min='+end_min+'&currentAppId='+$scope.appointment.id).success(function (data) {
        $scope.availabilityData = data;
        if(data.flag == false){
          $scope.isAvailDocter = true;  
        }
        else{
         $scope.isAvailDocter = false;   
        }
        
      });
    }
    //set end date
    var defaulDuration ='';
    $scope.updateDuration = function (data, id) {
      id = parseInt(id);
      var selectedDate=Date.parse('1-1-2000 ' + $scope.startTime);
      var newSelectedDate=new Date(selectedDate);
      for (i = 0; i < data.length; i++) {
        if (data[i].id == id) {
          var defaulDuration = data[i].duration_time;
          var newEndDate = new Date(newSelectedDate.getTime() + defaulDuration * 60000);
          $scope.selectedEndHour = newEndDate.getHours();
          $scope.selectedEndMin = newEndDate.getMinutes();
          $scope.appointment.end_hr = $scope.selectedEndHour;
          $scope.appointment.end_min = $scope.selectedEndMin;
        }
      }
      $rootScope.checkAvailbilityEdit();
    }


    //create new appointment
    $scope.updatePrac = function (data,id) {
      var promise = $rootScope.getAppointmentType(id, $scope.appointment.appointment_type_info);
      promise.then(function (greeting) {
        if ($rootScope.appTypeList.default_appointment_type != null) {
          $scope.appointment.appointment_type_id = ($rootScope.appTypeList.default_appointment_type).toString();
          $scope.updateDuration(data,$scope.appointment.appointment_type_id);
        } 
        else {
          $scope.appointment.appointment_type_id = ($rootScope.appointmentTypeList[0].id).toString();
          $scope.updateDuration(data,$scope.appointment.appointment_type_id);
        }
        $rootScope.checkAvailbilityEdit();
      }, function (reason) {
        alert('Failed: ' + reason);
      });
    }
    $scope.checkAvailDate = function(){
      $rootScope.checkAvailbilityEdit();
    }
    //update Appointment
    
    $scope.pushWeekDays = function (data) {
      $scope.weekDay = [];
      var i = 0
      angular.forEach(data, function (value, key) {
        if (value == true) {
          var breakKey = new Array();
          breakKey = key.split("");
          $scope.weekDay.push(parseInt(breakKey[3]));
          i++;
        }
      });
    }
    $scope.updateAppointment = function (data) {
      
      if(!data.patient_id){
        $scope.have_error=true;
        $scope.app_error="appointment.selectPatientMsg";
        $timeout(function () { $scope.have_error=false; }, 3000);
      }
      else if (!angular.isNumber(data.patient_id)) {
        $scope.notValidPatient = true;
      }
      else if(data.repeat_by!="None"){
        if(data.repeat_start == '' || data.repeat_start == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterRepeatEveryMsg";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.repeat_start)){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.repeat_start > 500 || data.repeat_start == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.repeat_end == '' || data.repeat_end == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterEndsAfter";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.repeat_end)){
          $scope.have_error=true;
          $scope.app_error="appointment.endsShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.repeat_end > 500 || data.repeat_end == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.endsBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if($scope.weekDay.length==0 && data.repeat_by=="week"){
          $scope.have_error=true;
          $scope.app_error="appointment.atleastOneDayRepeat";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else{
          $scope.popUpLoading = true;
          data.week_days=$scope.weekDay;
          if (data.repeat_by == 'None') {
            data.repeat_by = null;
          }
          data = {appointment: data}
          $http.put('/appointments/' + event.id, data).success(function (data) {
            $scope.popUpLoading = true;
            if (data.flag == true) {
              $modalInstance.dismiss('cancel');
              $translate('toast.updateAppointment').then(function (msg) {
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
      }
      else{
        $scope.popUpLoading = true;
        data.week_days=$scope.weekDay;
        if (data.repeat_by == 'None') {
          data.repeat_by = null;
        }
        data = {appointment: data}
        $http.put('/appointments/' + event.id, data).success(function (data) {
          $scope.popUpLoading = true;
          if (data.flag == true) {
            $modalInstance.dismiss('cancel');
            $translate('toast.updateAppointment').then(function (msg) {
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
    }
  }
]);
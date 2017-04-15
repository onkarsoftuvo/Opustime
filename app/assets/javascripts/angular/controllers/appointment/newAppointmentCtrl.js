/*new appointment controler*/
app.controller('newAppointmentCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  'filterFilter',
  '$modalInstance',
  'event',
  '$filter',
  '$timeout',
  'uiCalendarConfig',
  'Data',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, event, $filter, $timeout, uiCalendarConfig, Data, $translate) {
    /*close modal*/
    $scope.popUpLoading = false;
    var currentUser = localStorage.currentUser;
    UserSettings = JSON.parse(localStorage.UserSettings);
    if(UserSettings[currentUser] == undefined){
      UserSettings[currentUser] = {};
    }
    $scope.have_error = false;
    $scope.inFuture = false;
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $rootScope.endTimeError=false;
    $scope.newAppointmentSection = false;
    $scope.existingPatient = true;
    $scope.waitList = false;
    $scope.waitListShow = true;
    $scope.chooseWaitList=false;
    $scope.nowaitList=true;
    $scope.waitlistExist=false;
    $scope.notValidPatient = false;
    $scope.fromWaitList=function(){
      $scope.chooseWaitList=true;
      $scope.existingPatient=false;
      $scope.waitListDate($scope.currentPrac);
      $scope.waitListShow=false;
      $scope.waitList=false;
    }
    $scope.fromExistingList=function(){
      $scope.chooseWaitList=false;
      $scope.existingPatient=true;
      $scope.waitListShow=true;
    }
    $scope.associated_app={};
    $scope.associated_app.isChecked=false;
    
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
    $scope.dob_picker = {
      opened: false
    };
    $scope.open = function ($event) {
      $scope.date.opened = true;
    };
    $scope.DOB = function ($event) {
      $scope.dob_picker.opened = true;
    };
    //set start date
    var date = new Date();
    $scope.dobMaxDate=date;
    var selectedDate = event._d;
    var selected_Date = moment.utc(event._d).format("YYYY-MM-DD");
    var selected_Date_date = moment.utc(event._d).format("DD");
    var selected_Date_month = moment.utc(event._d).format("MM");
    var selected_Date_year = moment.utc(event._d).format("YYYY");
    $scope.selectedHour = selectedDate.getUTCHours();
    $scope.selectedMin = selectedDate.getUTCMinutes();
    //set end date
    var defaulDuration = $rootScope.appointmentTypeList[0].duration_time;
    var newEndDate = new Date(selectedDate.getTime() + defaulDuration * 60000);
    $scope.selectedEndHour = newEndDate.getUTCHours();
    $scope.selectedEndMin = newEndDate.getUTCMinutes();
    $scope.appointment = {};
    $scope.appointment.end_hr = $scope.selectedEndHour;
    $scope.appointment.end_min = $scope.selectedEndMin;
    $scope.updateDuration = function (data, id) {
      console.log(id);
      if(id != 'unavailable_block'){
        id = parseInt(id);
        for (i = 0; i < data.length; i++) {
          if (data[i].id == id) {
            var defaulDuration = data[i].duration_time;
            var newEndDate = new Date(selectedDate.getTime() + defaulDuration * 60000);
            $scope.selectedEndHour = newEndDate.getUTCHours();
            $scope.selectedEndMin = newEndDate.getUTCMinutes();
            $scope.appointment.end_hr = $scope.selectedEndHour;
            $scope.appointment.end_min = $scope.selectedEndMin;
          }
        }
        $rootScope.checkAvailbility();
      }
      else{
        console.log('go un');
        $modalInstance.dismiss('cancel');
        $rootScope.unavailableActivate = true;
        var modalInstance = $uibModal.open({
          templateUrl: 'unavailBlock.html',
          controller: 'unavailBlockCtrl',
          size: 'large_modal waitList_modal',
          windowClass: "modal in",
          resolve: {
            event: function () {
              return event;
            }
          }
        });
      }
    }
    
    //get patients list
    $rootScope.getPatientsData();
    //filter patient list with typehead(replace id with name)
    console.log($rootScope.PatientListData);
    $scope.formatLabel = function (model) {
      $scope.have_error=false;
      if(model!==undefined){
        Data.get('/patients/'+model+'/has_wait_list').then(function (results) {
          $scope.getListName=results;
          $scope.notValidPatient = false;
          if(model!=results.wait_list_id && results.flag==true){
            if($scope.waitList){
              $scope.waitlistExist=true;
              $scope.stopSubmit=true;
            }
          }
          else{
            $scope.waitlistExist=false;
            $scope.stopSubmit=false;
          }
        });
      }
      for (var i = 0; i < $rootScope.listLength; i++) {
        if (model === $rootScope.PatientListData[i].id) {
          return $rootScope.PatientListData[i].first_name + ' ' + $rootScope.PatientListData[i].last_name;
        }
      }
    };
    //get docters list
    $scope.getDoctersList = function () {
      $http.get('/settings/doctors').success(function (data) {
        $scope.DoctersList = data.practitioners;
      });
    }
    $scope.getDoctersList();
    //create new appointment
    $scope.updatePrac = function (data,id) {
      $scope.currentPrac=id;
      $scope.waitListDate(id);
      var promise = $rootScope.getAppointmentType(id);
      promise.then(function (greeting) {
        if($rootScope.anotherAppData!=null){
          $scope.appointment.patient_id=$rootScope.anotherAppData.patient_detail.patient_id;
          $rootScope.anotherApp=false;
          $rootScope.anotherAppData=null;
        }
        if($scope.waitListData==''){
          $scope.appointment.appointment_type_id = $rootScope.appTypeList.default_appointment_type;
        }
        if ($rootScope.appTypeList.default_appointment_type != null) {
          if($scope.chooseWaitList!=true){
            $scope.appointment.appointment_type_id = ($rootScope.appTypeList.default_appointment_type).toString();
          }
          $scope.updateDuration($rootScope.appointmentTypeList,$scope.appointment.appointment_type_id);
        } 
        else {
          if($scope.chooseWaitList!=true){
            $scope.appointment.appointment_type_id = ($rootScope.appointmentTypeList[0].id).toString();
            ;
          }
          $scope.updateDuration(data,$scope.appointment.appointment_type_id);
        }
        $rootScope.checkAvailbility();
        $scope.filerDocter(id);
      }, function (reason) {
        alert('Failed: ' + reason);
      });
    }



    $scope.Patient = {};
    //get Reffral Type
    $scope.getReferralType = function () {
      $http.get('/referrals').success(function (results) {
        console.log(results);
        $scope.ReferralTypeList = results;
      })
    }
    $scope.getReferralType();
    //get patient consession type
    $scope.Patient.concession_type = 'none';
    $scope.getDoctorList = function () {
      $http.get('/patients/doctors').success(function (list) {
        $scope.DoctorList = list;
      });
    }
    $scope.getDoctorList();
    
    
    //get related patients
    $scope.getRelatedPatient = function () {
      $http.get('/patients/related_patients').success(function (list) {
        $scope.PatientListRefine = list;
      });
    }
    //get refine patients
    $scope.PatientListRefinef = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.PatientListRefine, query)
    }
    //get contacts
    $scope.Contact = function () {
      $http.get('/patients/contacts').success(function (list) {
        $scope.contactsLists = list;
      });
    }
    $scope.Contact();

    $scope.Contactf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.contactsLists, query)
    }

    // Get Referral type
    $scope.BindRefreltype = function () {
      $scope.SelectedReferral = filterFilter($scope.ReferralTypeList, {
        referral_source: $scope.appointment.new_patient.referral_type
      });
      $scope.SelectedReferral_type_subcats = $scope.SelectedReferral[0].referral_type_subcats;
      $scope.appointment.new_patient.referrer = '';
    }
    $scope.getRelatedPatient();
    //get contact list
    $scope.getContactList = function () {
      $http.get('/patients/related_patients').success(function (list) {
        $scope.ContactList = list;
      })
    }
    $scope.getContactList();







    $scope.filerDocter=function(id){
      $scope.DoctersList.forEach(function (doc) {
        if(doc.id==id){
          doc.ischecked = true;
        }
        else{
          doc.ischecked = false;
        }
      });
    }

    $rootScope.currentBusiness.id
    $scope.waitListPatient = 'null'
    $scope.waitListDate=function(id){
      $http.get('/wait_lists/'+$rootScope.currentBusiness.id+'/practitioner/'+id).success(function (data) {
        $scope.waitListData='';
        $scope.WaitListContent = data.wait_lists;
        if($scope.WaitListContent.urgent.length!=0){
          $scope.nowaitList=true;
          $scope.waitListPatient='null';
        }
        else if($scope.WaitListContent.not_urgent.length!=0){
          $scope.nowaitList=true;
          $scope.waitListPatient='null';
        }
        else{
          $scope.nowaitList=false;
          $scope.waitListData='';
        }
      });
    }
    $scope.selectFromWaitList=function(id){
      if(id=='null'){
        $scope.waitListData='';
      }
      $scope.waitListPatient = id;
      var id=parseInt(id);
      if($scope.WaitListContent.urgent.length!=0){
        for(i=0;i<$scope.WaitListContent.urgent.length;i++){
          if($scope.WaitListContent.urgent[i].id==id){
            $scope.waitListData=$scope.WaitListContent.urgent[i];
            $scope.appointment.appointment_type_id=($scope.waitListData.appointment_type_id).toString();
          }
        }
      }
      if($scope.WaitListContent.not_urgent.length!=0){
        for(i=0;i<$scope.WaitListContent.not_urgent.length;i++){
          if($scope.WaitListContent.not_urgent[i].id==id){
            $scope.waitListData=$scope.WaitListContent.not_urgent[i];
            $scope.appointment.appointment_type_id=($scope.waitListData.appointment_type_id).toString();
          }
        }
      }
     // $scope.waitListPatient = 'null'
    }

    if ($rootScope.singlePrac == true) {
      $scope.updatePrac($rootScope.appointmentTypeList,UserSettings[currentUser].savedPractradio);
      $scope.appointment.user_id = parseInt(UserSettings[currentUser].savedPractradio);
      $scope.currentPrac=parseInt(UserSettings[currentUser].savedPractradio);
    } 
    else {
      $scope.updatePrac($rootScope.appointmentTypeList,UserSettings[currentUser].currentResource);
      $scope.appointment.user_id = parseInt(UserSettings[currentUser].currentResource);
      $scope.currentPrac=parseInt(UserSettings[currentUser].currentResource);
    }
    $scope.appointment.appnt_date = selected_Date;
    $scope.appointment.repeat_by = 'None';
    $scope.appointment.repeat_start=1;
    $scope.appointment.start_hr = $scope.selectedHour;
    $scope.appointment.start_min = $scope.selectedMin;
    $scope.creatNewAppointment = function () {
      $scope.newAppointmentSection = true;
      $scope.existingPatient = false;
      $scope.appointment.new_patient = {};
      //$scope.appointment.new_patient.title = 'dr';
      $scope.appointment.new_patient.contact_type = 'Mobile';
      $scope.appointment.new_patient.reminder_type = 'None';
      $scope.appointment.new_patient.gender = 'Male';
      $scope.appointment.new_patient.email = null;
      delete $scope.appointment.patient_id;
    }
    $scope.chooseExisting = function () {
      $scope.newAppointmentSection = false;
      $scope.existingPatient = true;
      delete $scope.appointment.new_patient;
      $scope.appointment.patient_id = '';
    }
    $scope.addToWaitlist = function () {
      $scope.waitList = true;
      $scope.waitListShow = false;
      $scope.appointment.wait_list = {};
      $scope.appointment.wait_list.availability = {};
      $scope.appointment.wait_list.availability.monday = true;
      $scope.appointment.wait_list.availability.tuesday = true;
      $scope.appointment.wait_list.availability.wednesday = true;
      $scope.appointment.wait_list.availability.thursday = true;
      $scope.appointment.wait_list.availability.friday = true;
      $scope.appointment.wait_list.availability.saturday = false;
      $scope.appointment.wait_list.availability.sunday = false;
      $scope.appointment.wait_list.options = {}
      $scope.appointment.wait_list.options.urgent = false;
      $scope.appointment.wait_list.options.outside_hours = false;
      $scope.appointment.wait_list.businesses = [];
      $scope.appointment.wait_list.practitioners = [];
      
      //$scope.inFuture = true;
      $scope.futureDate();
      if($scope.getListName.flag){
        $scope.waitlistExist=true;
        $scope.stopSubmit=true;
      }
      else{
        $scope.waitlistExist=false;
        $scope.stopSubmit=false;
      }
    }
    $scope.futureDate = function(){
      $rootScope.checkAvailbility();
      var curDate = $scope.appointment.appnt_date.getDate();
      var curMonth = $scope.appointment.appnt_date.getMonth();
      var curYear = $scope.appointment.appnt_date.getFullYear();
      var nowDate = date.getDate();
      var nowMonth = date.getMonth();
      var nowYear = date.getFullYear();
      var currentSelectedDate = new Date(curYear, curMonth, curDate);
      var nowFullDate = new Date(nowYear, nowMonth, nowDate);
      if(currentSelectedDate <= nowFullDate){
        if ($scope.waitList == true) {
          $scope.inFuture = true;
        }
      }
      else{
        $scope.inFuture = false;
      }
    }

    $scope.doNotShowWaitlist = function () {
      $scope.waitList = false;
      $scope.waitListShow = true;
      delete $scope.appointment.wait_list;
      $scope.waitlistExist=false;
      $scope.stopSubmit=false;
      $scope.inFuture = false;
    }
    $scope.deSelectAllDocters = function () {
      $scope.DoctersList.forEach(function (doc) {
        doc.ischecked = false;
      });
    }
    $scope.selectAllDocters = function () {
      $scope.appointment.wait_list.practitioners = [];
      $scope.DoctersList.forEach(function (doc) {
        doc.ischecked = true;
      });
    }
    $scope.deSelectAllBussiness = function () {
      $rootScope.BussinessList.forEach(function (doc) {
        if (doc.ischecked) {
          doc.ischecked = false;
        }
      });
    }
    $scope.selectAllBussiness = function () {
      $scope.appointment.wait_list.businesses = [];
      $rootScope.BussinessList.forEach(function (doc) {
        doc.ischecked = true;
      });
    }
    $scope.weekDay=[];
    var selectedDay=event._d.getUTCDay();
    var dayNo='day'+selectedDay;
    $scope.weekDay.push(selectedDay);
    var obj = {};
    obj[dayNo] = true;
    $scope.weekDays=obj;

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
    //Check availblity of Practitionar
    $scope.isAvailDocter = false;
    $rootScope.checkAvailbility = function(){
      var b_id = $rootScope.currentBusiness.id;
      var p_id = $scope.appointment.user_id;
      var app_id = parseInt($scope.appointment.appointment_type_id);
      var start_hr = $scope.appointment.start_hr;
      var start_min = $scope.appointment.start_min;
      var end_hr = $scope.appointment.end_hr;
      var end_min = $scope.appointment.end_min;
      var day = selected_Date_date;
      var month = selected_Date_month;
      var year = selected_Date_year;
      $http.get('/appointments/'+b_id+'/practitioners/'+p_id+'/'+app_id +'/availability?m='+month+'&y='+year+'&d='+day+'&start_hr='+start_hr+'&start_min='+start_min+'&end_hr='+end_hr+'&end_min='+end_min).success(function (data) {
        $scope.availabilityData = data;
        if(data.flag == false){
          $scope.isAvailDocter = true;  
        }
        else{
         $scope.isAvailDocter = false;   
        }
        
      });
    }
    

    $scope.creatAppointment = function (data) {
      if($scope.waitList==true){
        $scope.appointment.wait_list.businesses=[];
        $scope.appointment.wait_list.practitioners=[];
        if($scope.DoctersList.length==1){
          $scope.appointment.wait_list.practitioners.push({
            practitioner_id: $scope.DoctersList[0].id,
            is_selected: true,
          });
        }
        else{
          $scope.DoctersList.forEach(function (doc) {
            if (doc.ischecked) {
              $scope.appointment.wait_list.practitioners.push({
                practitioner_id: doc.id,
                is_selected: doc.ischecked,
              });
            }
          });
        }
        if($rootScope.BussinessList.length==1){
          $scope.appointment.wait_list.businesses.push({
            business_id: $rootScope.BussinessList[0].id,
            is_selected: true,
          });
        }
        else{
          $rootScope.BussinessList.forEach(function (business) {
            if (business.ischecked) {
              $scope.appointment.wait_list.businesses.push({
                business_id: business.id,
                is_selected: business.ischecked,
              });
            }
          });
        }
      }

      if($scope.existingPatient) {      
        if(!data.patient_id) {
          $scope.have_error=true;
          $scope.app_error="appointment.selectPatientMsg";
          $timeout(function () { $scope.have_error=false; }, 3000);
        } else if (!angular.isNumber(data.patient_id)) {
            $scope.notValidPatient = true;
        } else if(data.repeat_by!="None") {
            if(data.repeat_start == '' || data.repeat_start == undefined) {
                $scope.have_error=true;
                $scope.app_error="appointment.enterRepeatEveryMsg";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if(isNaN(data.repeat_start)) {
                $scope.have_error=true;
                $scope.app_error="appointment.everyShouldNumber";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if(data.repeat_start > 500 || data.repeat_start == 0){
                $scope.have_error=true;
                $scope.app_error="appointment.everyShouldBetween";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if(data.repeat_end == '' || data.repeat_end == undefined){
                $scope.have_error=true;
                $scope.app_error="appointment.enterEndsAfter";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if(isNaN(data.repeat_end)){
                $scope.have_error=true;
                $scope.app_error="appointment.endsShouldNumber";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if(data.repeat_end > 500 || data.repeat_end == 0){
                $scope.have_error=true;
                $scope.app_error="appointment.endsBetween";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else if($scope.weekDay.length==0 && data.repeat_by=="week"){
                $scope.have_error=true;
                $scope.app_error="appointment.atleastOneDayRepeat";
                $timeout(function () { $scope.have_error=false; }, 3000);
            } else {
                if ($scope.waitList) {
                  if (data.wait_list.availability.friday==false && data.wait_list.availability.monday==false && data.wait_list.availability.saturday==false && data.wait_list.availability.sunday==false && data.wait_list.availability.thursday==false && data.wait_list.availability.tuesday==false && data.wait_list.availability.wednesday==false) {
                    $scope.have_error=true;
                    $scope.app_error="appointment.atleastOneAvail";
                    $timeout(function () { $scope.have_error=false; }, 3000);
                  } else if (data.wait_list.businesses.length==0) {
                      $scope.have_error=true;
                      $scope.app_error="appointment.selectBusiness";
                      $timeout(function () { $scope.have_error=false; }, 3000);
                  } else if (data.wait_list.practitioners.length==0) {
                      $scope.have_error=true;
                      $scope.app_error="appointment.selectPrac";
                      $timeout(function () { $scope.have_error=false; }, 3000);
                  } else {
                      $scope.have_error=false;
                      $scope.creatAppAfterValidate(data);
                  }
                } else {
                  $scope.creatAppAfterValidate(data);
                }
              }
          } else if ($scope.inFuture) {
              $scope.have_error=true;
              $scope.app_error="appointment.SelectFutureDate";
              $timeout(function () { $scope.have_error=false; }, 3000);
            } else {
                if($scope.waitList){
                  if(data.wait_list.availability.friday==false && data.wait_list.availability.monday==false && data.wait_list.availability.saturday==false && data.wait_list.availability.sunday==false && data.wait_list.availability.thursday==false && data.wait_list.availability.tuesday==false && data.wait_list.availability.wednesday==false){
                    $scope.have_error=true;
                    $scope.app_error="appointment.atleastOneAvail";
                    $timeout(function () { $scope.have_error=false; }, 3000);
                  } else if(data.wait_list.businesses.length==0){
                      $scope.have_error=true;
                      $scope.app_error="appointment.selectBusiness";
                      $timeout(function () { $scope.have_error=false; }, 3000);
                  } else if (data.wait_list.practitioners.length==0) {
                      $scope.have_error=true;
                      $scope.app_error="appointment.selectPrac";
                      $timeout(function () { $scope.have_error=false; }, 3000);
                  } else {
                      $scope.have_error=false;
                      $scope.creatAppAfterValidate(data);
                  }
                } else {
                    $scope.creatAppAfterValidate(data);
                }
              }
          }
      else if($scope.newAppointmentSection){
        if(data.new_patient.email == ''){
          data.new_patient.email = null;
        }
        if(data.new_patient.first_name==undefined || data.new_patient.first_name==''){
          $scope.have_error=true;
          $scope.app_error="appointment.enterFirstName";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.new_patient.last_name==undefined || data.new_patient.last_name==''){
          $scope.have_error=true;
          $scope.app_error="appointment.enterLastName";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(!validateEmail(data.new_patient.email) && data.new_patient.email != null){
          $scope.have_error=true;
          $scope.app_error="appointment.entervalidEmail";
          $timeout(function () { $scope.have_error=false; }, 3000);
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
          else if($scope.weekDay.length==0 && data.repeat_by=="week"){
            $scope.have_error=true;
            $scope.app_error="appointment.atleastOneDayRepeat";
            $timeout(function () { $scope.have_error=false; }, 3000);
          }
          else{
            if($scope.waitList){
              if(data.wait_list.availability.friday==false && data.wait_list.availability.monday==false && data.wait_list.availability.saturday==false && data.wait_list.availability.sunday==false && data.wait_list.availability.thursday==false && data.wait_list.availability.tuesday==false && data.wait_list.availability.wednesday==false){
                $scope.have_error=true;
                $scope.app_error="appointment.atleastOneAvail";
                $timeout(function () { $scope.have_error=false; }, 3000);
              }
              else if(data.wait_list.businesses.length==0){
                $scope.have_error=true;
                $scope.app_error="appointment.selectBusiness";
                $timeout(function () { $scope.have_error=false; }, 3000);
              }
              else if(data.wait_list.practitioners.length==0){
                $scope.have_error=true;
                $scope.app_error="appointment.selectPrac";
                $timeout(function () { $scope.have_error=false; }, 3000);
              }
              else{
                $scope.have_error=false;
                $scope.creatAppAfterValidate(data);
              }
            }
            else{
              $scope.have_error=false;
              $scope.creatAppAfterValidate(data);
            }
          }
        }
        else if($scope.inFuture){
          $scope.have_error=true;
          $scope.app_error="appointment.SelectFutureDate";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else{
          if($scope.waitList){
            if(data.wait_list.availability.friday==false && data.wait_list.availability.monday==false && data.wait_list.availability.saturday==false && data.wait_list.availability.sunday==false && data.wait_list.availability.thursday==false && data.wait_list.availability.tuesday==false && data.wait_list.availability.wednesday==false){
              $scope.have_error=true;
              $scope.app_error="appointment.atleastOneAvail";
              $timeout(function () { $scope.have_error=false; }, 3000);
            }
            else if(data.wait_list.businesses.length==0){
              $scope.have_error=true;
              $scope.app_error="appointment.selectBusiness";
              $timeout(function () { $scope.have_error=false; }, 3000);
            }
            else if(data.wait_list.practitioners.length==0){
              $scope.have_error=true;
              $scope.app_error="appointment.selectPrac";
              $timeout(function () { $scope.have_error=false; }, 3000);
            }
            else{
              $scope.have_error=false;
              $scope.creatAppAfterValidate(data);
            }
          }
          else{
            $scope.have_error=false;
            $scope.creatAppAfterValidate(data);
          }
        }
      }
      else{
        if($scope.chooseWaitList==true){
          data.patient_id=$scope.waitListData.patient_id;
          data.existing_wait_list=$scope.waitListData.id;
        }
        if(!data.patient_id){
          $scope.have_error=true;
          $scope.app_error="Please Select patient from wait List";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else{
          $scope.creatAppAfterValidate(data); 
        }
      }
    }
    function validateEmail(email) {
      var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(email);
    }

    $scope.creatAppAfterValidate=function(data){
      if (data.new_patient && data.new_patient.dob != null && data.new_patient.dob != '') {
        var new_Date = new Date(data.new_patient.dob);
        var booking_month = new_Date.getMonth() + 1;
        var booking_Date = new_Date.getDate();
        if (booking_month < 10)
          booking_month = '0' + booking_month;
        if (booking_Date < 10)
          booking_Date = '0' + booking_Date;
        var booking_new_Date = new_Date.getFullYear() + '-' + booking_month + '-' + booking_Date;
        data.new_patient.dob = booking_new_Date;
      }
      console.log(data);
      $scope.popUpLoading = true;
      if (data.repeat_by == 'None') {
        data.repeat_by = null;
        data.repeat_start=null;
        data.repeat_end=null;
      }
      if(data.repeat_by != null){
        data.repeat_start=parseInt(data.repeat_start);
        data.repeat_end=parseInt(data.repeat_end);
      }
      if (data == undefined) {
        data = {
          appointment: {
            business_id: $rootScope.currentBusiness.id
          }
        };
        $scope.appointment = data;
      }
      else {
        data.business_id = $rootScope.currentBusiness.id;
      }
      $scope.appointment.week_days=$scope.weekDay;
      if($scope.waitListData.associated_appointment!=null){
        $scope.appointment.associated_appointment=$scope.waitListData.associated_appointment;
        $scope.appointment.associated_appointment_checked=$scope.associated_app.isChecked;
      }
      $scope.appointment = {
        appointment: $scope.appointment
      };
      $http.post('/appointments/', $scope.appointment).success(function (data) {
        if (data.flag) {
          $modalInstance.dismiss('cancel');
          $scope.popUpLoading = false;
          $rootScope.getWaitList();
          $translate('toast.appCreated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          uiCalendarConfig.calendars['myCalendar3'].fullCalendar('refetchEvents')
          $rootScope.getEvents();
        }
        else {
            for(var i = 0;i<data.error.length;i++){
                if(data.error[i].error_name === 'patient contacts.contact no'){
					$scope.error_name = true;
                    data.error[i].error_name = 'Patient contact no';                    
                }
            }
            if ($scope.error_name) {
                $scope.error_name = false;
                $rootScope.errors = data.error;
                $rootScope.showMultyErrorToast();
                $scope.popUpLoading = false;
            } else {
              $rootScope.getEvents();
              $modalInstance.dismiss('cancel');
              $scope.popUpLoading = false;
            }
        }
      });
    }
  }
]);
/*add wait list controler*/
app.controller('unavailBlockCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  'filterFilter',
  '$modalInstance',
  '$filter',
  '$timeout',
  'Data',
  'event',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, $filter, $timeout, Data, event, $translate) {
    /*close modal*/
    var currentUser = localStorage.currentUser;
    UserSettings = JSON.parse(localStorage.UserSettings);
    if(UserSettings[currentUser] == undefined){
      UserSettings[currentUser] = {};
    }
    $rootScope.updateUnavailbitiy=false;
    $scope.have_error=false;
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
    //set start date
    var date = new Date();
    var selectedDate = event._d;
    $scope.selectedHour = selectedDate.getUTCHours();
    $scope.selectedMin = selectedDate.getUTCMinutes();
    //set end date
    var defaulDuration = 30;
    var newEndDate = new Date(selectedDate.getTime() + defaulDuration * 60000);
    $scope.selectedEndHour = newEndDate.getUTCHours();
    $scope.selectedEndMin = newEndDate.getUTCMinutes();


    $scope.unAvail = {};
    $scope.unAvail.end_hr = $scope.selectedEndHour;
    $scope.unAvail.end_min = $scope.selectedEndMin;
    $scope.unAvail.repeat='None';
    $scope.unAvail.avail_date=selectedDate;
    $scope.unAvail.start_hr = $scope.selectedHour;
    $scope.unAvail.start_min = $scope.selectedMin;
    $scope.unAvail.repeat_every=1;
    if ($rootScope.singlePrac == true) {
      $scope.unAvail.user_id = parseInt(UserSettings[currentUser].savedPractradio);
    } 
    else {
      $scope.unAvail.user_id = parseInt(UserSettings[currentUser].currentResource);
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

    $scope.saveUnavailable=function(data){
      console.log(data);
      if (data.repeat!="None") {
        if(data.repeat_every == '' || data.repeat_every == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterRepeatEveryMsg";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.repeat_every)){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.repeat_every > 500 || data.repeat_every == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.ends_after == '' || data.ends_after == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterEndsAfter";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.ends_after)){
          $scope.have_error=true;
          $scope.app_error="appointment.endsShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.ends_after > 500 || data.ends_after == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.endsBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if($scope.weekDay.length==0 && data.repeat=="week"){
          $scope.have_error=true;
          $scope.app_error="appointment.atleastOneDayRepeat";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else{
          $scope.practitionar=data.user_id;
          data.ends_after=parseInt(data.ends_after);
          data.repeat_every=parseInt(data.repeat_every);
          if($rootScope.unavailableActivate==true){
            data.is_block=true;
          }
          else{
            data.is_block=false;
          }
          data.week_days=$scope.weekDay;
          if($scope.unAvail.repeat=='None'){
            $scope.unAvail.repeat=null;
            delete $scope.unAvail.ends_after;
            delete $scope.unAvail.repeat_every;
            delete data.week_days;
          }
          delete data.user_id;
          $scope.availability={availability:data};
          console.log($scope.availability);
          $http.post('/appointments/'+parseInt(UserSettings[currentUser].savedBusiness)+'/'+$scope.practitionar+'/availability', $scope.availability).success(function (data) {
            $rootScope.unavailableActivate=false;
            $rootScope.availableActivate=false;
            if (data.flag) {
              $modalInstance.dismiss('cancel');
              $translate('toast.createUnavail').then(function (msg) {
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
        $scope.practitionar=data.user_id;
        data.ends_after=parseInt(data.ends_after);
        data.repeat_every=parseInt(data.repeat_every);
        if($rootScope.unavailableActivate==true){
          data.is_block=true;
        }
        else{
          data.is_block=false;
        }
        data.week_days=$scope.weekDay;
        if($scope.unAvail.repeat=='None'){
          $scope.unAvail.repeat=null;
          delete $scope.unAvail.ends_after;
          delete $scope.unAvail.repeat_every;
          delete data.week_days;
        }
        delete data.user_id;
        $scope.availability={availability:data};
        $http.post('/appointments/'+parseInt(UserSettings[currentUser].savedBusiness)+'/'+$scope.practitionar+'/availability', $scope.availability).success(function (data) {
          $rootScope.unavailableActivate=false;
          $rootScope.availableActivate=false;
          if (data.flag) {
            $modalInstance.dismiss('cancel');
            $translate('toast.createUnavail').then(function (msg) {
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

/*edit unavailbility controler*/
app.controller('editUnavailBlockCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  'filterFilter',
  '$modalInstance',
  '$filter',
  '$timeout',
  'Data',
  'eventData',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, $filter, $timeout, Data, eventData, $translate) {
    /*close modal*/
    $rootScope.updateUnavailbitiy=true;
    var currentUser = localStorage.currentUser;
    UserSettings = JSON.parse(localStorage.UserSettings);
    if(UserSettings[currentUser] == undefined){
      UserSettings[currentUser] = {};
    }
    $scope.have_error=false;
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
    
    $scope.unAvail = {};
    $scope.unAvail.repeat_every=1;

    $scope.editUnavaility=function(id){ 
      Data.get('/appointments/availability/' + id + '/edit').then(function (results) {
        $scope.unAvail = results.appointment;
        $scope.unAvail.flag="0";
        $scope.weekDay=$scope.unAvail.week_days;
        $scope.weekDays={};
        var obj = {};
        for(i=0;i<$scope.unAvail.week_days.length;i++){
          var dayNo='day'+$scope.unAvail.week_days[i];
          obj[dayNo] = true;
        }
        $scope.weekDays=obj;
        if ($scope.unAvail.repeat==null) {
          $scope.unAvail.repeat="None";
        }
        $rootScope.cloading = false;
      });
    }
    $scope.editUnavaility(eventData.id);

    

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
    $scope.unAvail.repeat_every=1;
    $scope.saveUnavailable=function(data){
      if (data.repeat!="None") {
        if(data.repeat_every == '' || data.repeat_every == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterRepeatEveryMsg";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.repeat_every)){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.repeat_every > 500 || data.repeat_every == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.everyShouldBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.ends_after == '' || data.ends_after == undefined){
          $scope.have_error=true;
          $scope.app_error="appointment.enterEndsAfter";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(isNaN(data.ends_after)){
          $scope.have_error=true;
          $scope.app_error="appointment.endsShouldNumber";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if(data.ends_after > 500 || data.ends_after == 0){
          $scope.have_error=true;
          $scope.app_error="appointment.endsBetween";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else if($scope.weekDay.length==0 && data.repeat=="week"){
          $scope.have_error=true;
          $scope.app_error="appointment.atleastOneDayRepeat";
          $timeout(function () { $scope.have_error=false; }, 3000);
        }
        else{
          $scope.practitionar=data.user_id;
          data.ends_after=parseInt(data.ends_after);
          data.repeat_every=parseInt(data.repeat_every);
          data.flag=parseInt(data.flag);
          data.is_block=true;
          data.week_days=$scope.weekDay;
          if($scope.unAvail.repeat=='None'){
            $scope.unAvail.repeat=null;
            delete $scope.unAvail.ends_after;
            delete $scope.unAvail.repeat_every;
            delete data.week_days;
          }
          delete data.user_id;
          $scope.availability={availability:data};
          $http.put('/appointments/'+parseInt(UserSettings[currentUser].savedBusiness)+'/'+$scope.practitionar+'/availability/'+$scope.availability.availability.id, $scope.availability).success(function (data) {
            $rootScope.unavailableActivate=false;
            $rootScope.availableActivate=false;
            if (data.flag) {
              $modalInstance.dismiss('cancel');
              $translate('toast.updateUnavail').then(function (msg) {
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
        $scope.practitionar=data.user_id;
        data.ends_after=parseInt(data.ends_after);
        data.repeat_every=parseInt(data.repeat_every);
        data.flag=parseInt(data.flag);
        data.is_block=true;
        data.week_days=$scope.weekDay;
        if($scope.unAvail.repeat=='None'){
          $scope.unAvail.repeat=null;
          delete $scope.unAvail.ends_after;
          delete $scope.unAvail.repeat_every;
          delete data.week_days;
        }
        delete data.user_id;
        $scope.availability={availability:data};
        $http.put('/appointments/'+parseInt(UserSettings[currentUser].savedBusiness)+'/'+$scope.practitionar+'/availability/'+$scope.availability.availability.id, $scope.availability).success(function (data) {
          $rootScope.unavailableActivate=false;
          $rootScope.availableActivate=false;
          if (data.flag) {
            $modalInstance.dismiss('cancel');
            $rootScope.cloading = false;
            $translate('toast.updateUnavail').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.getEvents();
          }
          else {
            $modalInstance.dismiss('cancel');
            $rootScope.errors = data.error;
            $rootScope.showMultyErrorToast();
            $rootScope.cloading = false;
          }
        });
      }
    }
  }
]);


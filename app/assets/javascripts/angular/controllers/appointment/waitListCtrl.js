
/*add wait list controler*/
app.controller('addWaitListModalCtrl', [
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
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, $filter, $timeout, Data, $translate) {
    /*close modal*/
    $scope.popUpLoading = false;
    $scope.waitListErrorMsg = false;
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.waitlistExist=false;
    $rootScope.newWaitlist=true;

    $scope.dateOptions = {
      startDate: '2016-04-22',
      formatYear: 'yy',
      maxDate: new Date(2016, 5, 22),
      minDate: new Date(),
      startingDay: 1,
      showWeeks: false,
    };
    $scope.date = {
      opened: false
    };
    $scope.open = function ($event) {
      $scope.date.opened = true;
    };
    //$rootScope.getAppointmentType();

    
    //get patients list
    $rootScope.getPatientsData();
    //get docters list
    $scope.getDoctersList = function () {
      $http.get('/settings/doctors').success(function (data) {
        $scope.DoctersList = data.practitioners;
      });
    }
    $scope.getDoctersList();
    //filter patient list with typehead(replace id with name)
    $scope.formatLabel = function (model) {
      if(model!==undefined){
        Data.get('/patients/'+model+'/has_wait_list').then(function (results) {
          //$rootScope.allAppointments = results;
          if(results.flag){
            $scope.waitlistExist=true;
            $scope.stopSubmit=true;
            $scope.getListName=results;
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

    $scope.checkWaitList = function (id) {
      $modalInstance.dismiss('cancel');
      var modalInstance = $uibModal.open({
        templateUrl: 'addWaitListModal.html',
        controller: 'editWaitListCtrl',
        size: 'large_modal waitList_modal',
        resolve: {
          listId: function () {
            return id;
          }
        }
      });
    }

    $scope.wait_list = {};
    $scope.wait_list.availability = {};
    var date=new Date();
    var currentDate=new Date();
    var currentDay=currentDate.getDate();
    var newDate=date.setDate((currentDate).getDate()+15)
    $scope.wait_list.remove_on=new Date(newDate);
    var newd=new Date();
    var newStartDate=newd.setDate((currentDate).getDate()+1)
    $scope.minDate=new Date(newStartDate);

    $scope.wait_list.availability.monday = true;
    $scope.wait_list.availability.tuesday = true;
    $scope.wait_list.availability.wednesday = true;
    $scope.wait_list.availability.thursday = true;
    $scope.wait_list.availability.friday = true;
    $scope.wait_list.availability.saturday = false;
    $scope.wait_list.availability.sunday = false;
    $scope.wait_list.options = {}
    $scope.wait_list.options.urgent = false;
    $scope.wait_list.options.outside_hours = false;
    $scope.wait_list.businesses = [];
    $scope.wait_list.practitioners = [];
    //get all appointments
    $scope.allAppointment=function(){
      Data.get('/settings/appointment_type').then(function (results) {
        $rootScope.allAppointments = results;
        $scope.wait_list.appointment_type_id=$rootScope.allAppointments[0].id;
      });
    }
    $scope.allAppointment();

    $scope.deSelectAllDocters = function () {
      $scope.DoctersList.forEach(function (doc) {
        doc.is_selected = false;
      });
    }
    $scope.selectAllDocters = function () {
      $scope.wait_list.practitioners = [];
      $scope.DoctersList.forEach(function (doc) {
        doc.is_selected = true;
      });
    }
    $scope.deSelectAllBussiness = function () {
      $rootScope.BussinessList.forEach(function (doc) {
        doc.is_selected = false;
      });
    }
    $scope.selectAllBussiness = function () {
      $scope.wait_list.businesses = [];
      $rootScope.BussinessList.forEach(function (doc) {
        doc.is_selected = true;
      });
    }

    $scope.addWaitList=function(data){
      $scope.wait_list.practitioners=[];
      $scope.wait_list.businesses=[];
      if($scope.DoctersList.length==1){
        $scope.wait_list.practitioners.push({
          practitioner_id: $scope.DoctersList[0].id,
          is_selected: true,
        });
      }
      else{
        $scope.DoctersList.forEach(function (doc) {
          if (doc.is_selected) {
            $scope.wait_list.practitioners.push({
              practitioner_id: doc.id,
              is_selected: doc.is_selected,
            });
          }
        });
      }

      if($rootScope.BussinessList.length==1){
        $scope.wait_list.businesses.push({
          business_id: $rootScope.BussinessList[0].id,
          is_selected: true,
        });
      }
      else{
        $rootScope.BussinessList.forEach(function (business) {
          if (business.is_selected) {
            $scope.wait_list.businesses.push({
              business_id: business.id,
              is_selected: business.is_selected,
            });
          }
        });
      }

      //check validations
      if(data.patient_id == undefined || data.patient_id == ''){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectPatientMsg";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.availability.friday == false && data.availability.monday == false && data.availability.saturday == false && data.availability.sunday == false && data.availability.thursday == false && data.availability.tuesday == false && data.availability.wednesday == false){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.atleastOneAvail";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.businesses.length == 0){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectBusiness";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.practitioners.length == 0){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectPrac";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else{
        $scope.popUpLoading = true;
        $scope.wait_list={wait_list:$scope.wait_list}
        $http.post('/wait_lists', $scope.wait_list).success(function (data) {
          if (data.flag) {
            $modalInstance.dismiss('cancel');
            $scope.popUpLoading = true;
            $translate('toast.createWaitlist').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.getWaitList();
          } 
          else {
            $modalInstance.dismiss('cancel');
            $rootScope.errors = data.error;
            $rootScope.showMultyErrorToast();
            $scope.popUpLoading = true;
          }
        });
      }
    }
  }
]);
/*delete wait list confirm controler*/
app.controller('waitListconfirmationCtrl', [
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
  'listId',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, $filter, $timeout, Data, listId, $translate) {
   /*close modal*/
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.confirmDelete=function(){
      $rootScope.cloading=true;
      $http.delete ('/wait_lists/' + listId).success(function (data) {
        $rootScope.cloading = false;
        if (data.flag) {
          $modalInstance.dismiss('cancel');
          $translate('toast.deleteWaitlist').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getWaitList();
        }
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = data.error;
          $rootScope.showMultyErrorToast();
        }
      });
    }
  }
]);
/*edit wait list controler*/
app.controller('editWaitListCtrl', [
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
  'listId',
  '$q',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, filterFilter, $modalInstance, $filter, $timeout, Data, listId, $q, $translate) {
    /*close modal*/
    $scope.waitListErrorMsg = false;
    $scope.popUpLoading = false;
    $rootScope.BussinessList.forEach(function (docs) {
        docs.is_selected = false;
    });
    
    $scope.waitlistExist=false;
    $rootScope.newWaitlist=false;
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
    
    //get patients list
    $rootScope.getPatientsData();
    
    var currentDate=new Date();
    var newd=new Date();
    var newStartDate=newd.setDate((currentDate).getDate()+1)
    $scope.minDate=new Date(newStartDate);

    //filter patient list with typehead(replace id with name)
    $scope.formatLabel = function (model) {
      if(model!==undefined){
        Data.get('/patients/'+model+'/has_wait_list').then(function (results) {
          if(listId!=results.wait_list_id && results.flag==true){
            $scope.waitlistExist=true;
            $scope.stopSubmit=true;
            $scope.getListName=results;
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

    $scope.checkWaitList = function (id) {
      $modalInstance.dismiss('cancel');
      var modalInstance = $uibModal.open({
        templateUrl: 'addWaitListModal.html',
        controller: 'editWaitListCtrl',
        size: 'large_modal waitList_modal',
        resolve: {
          listId: function () {
            return id;
          }
        }
      });
    }
    //get docters list
    $scope.getDoctersList = function () {
      return $q(function (resolve, reject) {
        setTimeout(function () {
          resolve('hi');
          $http.get('/settings/doctors').success(function (data) {
            $scope.DoctersList = data.practitioners;
          });
        });
      }, 1000);
    }
    var getDoc=$scope.getDoctersList();

    //get all appointments
    $scope.allAppointment=function(){
      Data.get('/settings/appointment_type').then(function (results) {
        $rootScope.allAppointments = results;
      });
    }
    $scope.allAppointment();

    $scope.deSelectAllDocters = function () {
      $scope.DoctersList.forEach(function (doc) {
        doc.is_selected = false;
      });
    }
    $scope.selectAllDocters = function () {
      $scope.wait_list.practitioners = [];
      $scope.DoctersList.forEach(function (doc) {
        doc.is_selected = true;
      });
    }
    $scope.deSelectAllBussiness = function () {
      $rootScope.BussinessList.forEach(function (doc) {
        if (doc.is_selected) {
          doc.is_selected = false;
        }
      });
    }
    $scope.selectAllBussiness = function () {
      $scope.wait_list.businesses = [];
      $rootScope.BussinessList.forEach(function (doc) {
        doc.is_selected = true;
      });
    }
    //edit wait list
    getDoc.then(function (greeting) {
      $scope.editWaitList=function(){
        $scope.popUpLoading = true;
        Data.get('/wait_lists/'+listId+'/edit').then(function (results) {
          $scope.wait_list=results.wait_list;
          $scope.popUpLoading = false;
          for(i=0;i<$scope.wait_list.practitioners.length;i++){
            $scope.DoctersList.forEach(function (doc) {
              if(doc.id==$scope.wait_list.practitioners[i].practitioner_id && $scope.wait_list.practitioners[i].is_selected==true){
                doc.is_selected = true;
              }
            });
          }
          for(j=0;j<$scope.wait_list.businesses.length;j++){
            $rootScope.BussinessList.forEach(function (docs) {
              if(docs.id==$scope.wait_list.businesses[j].business_id && $scope.wait_list.businesses[j].is_selected==true){
                docs.is_selected = true;
              }
            });
          }
        });
      }
      $scope.editWaitList();
    });


    $scope.updateWaitList=function(data){
      //$rootScope.cloading=true;
      
      $scope.DoctersList.forEach(function (doc) {
        for(i=0;i<$scope.wait_list.practitioners.length;i++){
          if(doc.id==$scope.wait_list.practitioners[i].practitioner_id){
            if(doc.is_selected==true){
              $scope.wait_list.practitioners[i].is_selected=true;
            }
            else{
              $scope.wait_list.practitioners[i].is_selected=false;
            }
          }
        }
      });
      $rootScope.BussinessList.forEach(function (business) {
        for(i=0;i<$scope.wait_list.businesses.length;i++){
          if(business.id==$scope.wait_list.businesses[i].business_id){
            if(business.is_selected==true){
              $scope.wait_list.businesses[i].is_selected=true;
            }
            else{
              $scope.wait_list.businesses[i].is_selected=false;
            }
          }
        }
      });

      //check validations
      if(data.patient_id == undefined || data.patient_id == ''){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectPatientMsg";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.availability.friday == false && data.availability.monday == false && data.availability.saturday == false && data.availability.sunday == false && data.availability.thursday == false && data.availability.tuesday == false && data.availability.wednesday == false){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.atleastOneAvail";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.businesses.length == 0){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectBusiness";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else if(data.practitioners.length == 0){
        $scope.waitListErrorMsg = true;
        $scope.waitListError = "appointment.selectPrac";
        $timeout(function () { $scope.waitListErrorMsg=false; }, 3000);
      }
      else{
        $scope.popUpLoading = true;
        $scope.wait_list={wait_list:$scope.wait_list}
        $http.put('/wait_lists/'+data.id, $scope.wait_list).success(function (data) {
          $scope.popUpLoading = false;
          if (data.flag) {
            $modalInstance.dismiss('cancel');
            $translate('toast.updateWaitlist').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.getWaitList();
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


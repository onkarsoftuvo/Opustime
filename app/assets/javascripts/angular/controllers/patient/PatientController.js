app.controller('PatientCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$http',
  'filterFilter',
  '$modal',
  '$filter',
  '$timeout',
  '$translate',
  '$state',
  'pageService',
  function ($rootScope, $scope, Data, $http, filterFilter, $modal, $filter, $timeout, $translate, $state, pageService) {

    init();

    function init(){
      $scope.pagingData = {};
      $scope.pagingData.fromFilter = '',
      $scope.pagingData.toFilter = '',
      $scope.pagingData.Page = 1;
      $scope.pagingData.TotalItems = 0;
      $scope.pagingData.PageSize = 30;
      $scope.showGrid = false;
    }

    $scope.searchPatienttext = '';
    //get user role and authontications
    $scope.userRole = function () {
      $http.get('/patients/get/authority').success(function (data) {
        if (!data.code) {
          $rootScope.roleData = data;
        }
      });
    }
    $scope.userRole();
    //$scope.pagging = [];
    $scope.noModule = false;
    //Get Patient Data
    // $scope.getPatientsData = function () {
    //   $http.get('/patients').success(function (data) {
    //     if (data.code) {
    //       $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
    //       $state.go('dashboard');
    //     }
    //     else{
    //       $scope.PatientListData = data;
    //       if ($scope.PatientListData.patient_list.length == 0) {
    //         $scope.noModule = true;
    //         $scope.noData = true;
    //       }
    //       $scope.pagging = [];
    //       for (i = 1; i <= $scope.PatientListData.pagination.total_pages; i++) {
    //         $scope.pagging.push({
    //           pageNo: i
    //         });
    //       }
    //     }
    //   });
    // }
    // $scope.getPatientsData();

    $scope.patientLogs = function(pagingData) {
      $scope.PatientList = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/patients?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = $http.get('/patients?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.success(function(data){
        if(data.patient_list.length != 0){
          for (var i = 0; i < data.patient_list.length; i++) {
            data.patient_list[i].isopen = false;
          }
          $scope.PatientList = data.patient_list;
            console.log($scope.PatientList);
          $scope.PatientListData = data;
          $scope.pagingData.TotalItems = data.total;
          $scope.noRecordFount = false;
          $scope.showGrid = true;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
      });
    }
    $scope.patientLogs($scope.pagingData);

    
    //pagination code---------------------------------------------------
   
    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.patientLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };

    //pagination ends here----------------------------------------------------
    
    //get patient list
    $scope.getPatientList = function () {
      $http.get('/patients').success(function (list) {
        if (!list.code) {
          $scope.PatientList = list;
        }
      });
    }

    //open next appointment
    $scope.openAppointment = function(data){
      if(data){
        localStorage.setItem('currentAppointment' ,data);
        $state.go('appointment');
      }
    }

    //Clear patient logs
    $scope.clearLogs = function() {
      $scope.pagingData.fromFilter = "";
      $scope.patientLogs($scope.pagingData); 
    }

    //filter for patient search list
  //   $scope.noRecordFount = false;
  //   var _timeout;
  //   $scope.patientSearch = function (Term) {
  //     if (_timeout) { //if there is already a timeout in process cancel it
  //       $timeout.cancel(_timeout);
  //     }
  //     _timeout = $timeout(function () {
  //       $rootScope.cloading = true;
  //       $http.get('/patients?q=' + Term).success(function (data) {
  //         $scope.PatientListData = data;
  //         if ($scope.PatientListData.patient_list.length == 0) {
  //           $scope.noRecordFount = true;
  //           $scope.noModule = false;
  //         } 
  //         else {
  //           $scope.noRecordFount = false;
  //         }
  //         $rootScope.cloading = false;
  //       });
  //       _timeout = null;
  //     }, 1000);
  //   }
  //   $scope.getPatientList();    
  }
]);

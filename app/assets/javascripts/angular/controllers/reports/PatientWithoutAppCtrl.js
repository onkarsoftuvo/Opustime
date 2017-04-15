app.controller('PatientWithoutAppCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'monthNameService',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, monthNameService, $state) {
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.noData = false;

    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    
    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.allLoc = '';
      $scope.allDoc = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/patient_reports/list/upcoming_export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/patient_reports/list/upcoming_pdf.pdf?'
          $scope.printIndication = false; 
        }
        else{
          var baseurl = '/patient_reports/list/without_upcoming_appointments?'
        }
        var filter = $scope.filter;
        if (filter.from) {
          baseurl += 'start_date=' + (filter.from.getDate() + '/' + (parseInt(filter.from.getMonth()) + 1) + '/' + filter.from.getFullYear());
        }
        if (filter.to) {
          baseurl += '&end_date=' + (filter.to.getDate() + '/' + (parseInt(filter.to.getMonth()) + 1) + '/' + filter.to.getFullYear());
        }
        return resolve(baseurl)
      });
    }
    $scope.filterpatientNoApp = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.patientsNoAppList = data.patients;
          if($scope.patientsNoAppList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          $rootScope.cloading = false;
        });
      })
    }

    //onload table content data
    $scope.patientNoApp = function () {
      $rootScope.cloading = true;
      Data.get('/patient_reports/list/without_upcoming_appointments').then(function (data) {
        if (data.patients) {
          $scope.patientsNoAppList = data.patients;
          if($scope.patientsNoAppList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          $scope.filter.from = '';
          $scope.filter.to = '';
        }
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        
        $rootScope.cloading = false;
      });
    }
    $scope.patientNoApp();

    //export data
    $scope.export = function(){
      var win = window.open('/patient_reports/list/upcoming_export.csv', '_blank')
      $scope.exportIndication = true;
      var promise = buildFilters();
      promise.then(function (results) {
        var win = window.open(results, '_blank');
      });
    }

    //print data
    $scope.print = function(){
      $scope.printIndication = true;
      var promise = buildFilters();
      promise.then(function (results) {
        var win = window.open(results, '_blank');
      });
    }
  }
]);

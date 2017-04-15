app.controller('patientBirthdayReportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'monthNameService',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, monthNameService, $state) {
    $scope.noBirthday = false;
    $scope.$state = $state;
    //set current month in dropdown
    $scope.monthName = ((new Date()).getMonth()+1).toString();
    $scope.showMonth = $scope.monthName;
    
    //get month name from month no
    $scope.getMonthName = function(monthNo){
      $scope.curMonth = monthNameService.month(parseInt(monthNo)-1);
    }
    $scope.getMonthName($scope.showMonth);

    //get Patient's birthday List
    $scope.patientBirthDayList = function(){
      $rootScope.cloading = true;
      Data.get('/patient_reports?month_no='+ $scope.monthName).then(function (data) {
        if (data.month_wise_patients) {
          $scope.birthdayList = data.month_wise_patients;
          if ($scope.birthdayList.length == 0) {
            $scope.noBirthday = true;
          }
          else{
            $scope.noBirthday = false;
          }
          $scope.getMonthName($scope.monthName);
        }
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard')
        }
        $rootScope.cloading = false;
      });
    }
    $scope.patientBirthDayList();

    //export Birthday data
    $scope.exportBirthday = function(){
      var win = window.open('/patient_reports/birthday_export.csv?month_no='+ $scope.monthName, '_blank');
    }  

    //print Birthday data
    $scope.printBirthday = function(){
      var win = window.open('/patient_reports/birthday_pdf.pdf?month_no='+ $scope.monthName, '_blank');
    }  
  }
]);

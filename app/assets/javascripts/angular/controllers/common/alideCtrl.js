app.controller('alideCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$state',
  function ($scope, $location, $rootScope, $timeout, $http, $state) {
    /*$scope.AutherizeDashboard = function(){
	  $http.get('/dashboard/modules').success(function(response){
	    console.log(response);
	    $rootScope.DashboardLinks=response;
	  });
    }
  	$scope.AutherizeDashboard();*/
    $scope.isPatient = function () {
      if ($state.current.name == 'patient' || $state.current.name == 'patient-detail' || $state.current.name == 'patient-edit' || $state.current.name == 'AccountStatement') {
        return true;
      }
      else {
        return false;
      }
    };
    $scope.open_settings = false;
    $scope.open_reports = false;
    $scope.overlay = false;
    var checkMenuStatus = 0;
    $scope.openSettingsMenu = function(){
      if (checkMenuStatus == 0) {
        $scope.open_settings = true;
        $scope.open_reports = false;
        $scope.open_sms = false;
        $scope.overlay = true;
        checkMenuStatus = 1;
        checkReports = 0;
        checkSms = 0;
      }
      else{
        $scope.open_settings = false; 
        $scope.overlay = false;
        checkMenuStatus = 0;
      }
    }
    var checkReports = 0;
    $scope.openReportsMenu = function(){
      if (checkReports == 0) {
        $scope.open_reports = true;
        $scope.open_settings = false;
        $scope.open_sms = false;
        $scope.overlay = true;
        checkReports = 1;
        checkMenuStatus = 0;
        checkSms = 0;
      }
      else{
        $scope.open_reports = false; 
        $scope.overlay = false;
        checkReports = 0;
      }
    }
    var checkSms = 0;
    $scope.openSmsMenu = function(){
      if (checkSms == 0) {
        $scope.open_reports = false;
        $scope.open_settings = false;
        $scope.open_sms = true;
        $scope.overlay = true;
        checkSms = 1;
        checkMenuStatus = 0;
        checkReports = 0;
      }
      else{
        $scope.open_sms = false; 
        $scope.overlay = false;
        checkSms = 0;
      }
    }
    $scope.closeMenu = function(){
      $scope.open_reports = false;
      $scope.open_settings = false;
      $scope.open_sms = false; 
      $scope.overlay = false;
      checkMenuStatus = 0;
      checkReports = 0;
      checkSms = 0;
    }
    /*$rootScope.$on('$stateChangeSuccess', function(event, toState, toParams) {
      if (toState.name == 'patient' || toState.name == 'patient-detail' || toState.name == 'patient-edit' || toState.name == 'AccountStatement') {
        $scope.isPatient = true;
      }
      else{
      	$scope.isPatient = false;
      }
    });*/
  }
]);

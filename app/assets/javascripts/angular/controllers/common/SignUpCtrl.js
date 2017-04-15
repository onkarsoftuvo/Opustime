// JavaScript Document
var opusSignUp = angular.module('Zuluapp');
opusSignUp.controller('SignUpCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$state',
  '$stateParams',
  'Data',
  'Signup',
  '$window' ,
  function ($scope, $location, $rootScope, $timeout, $http, $state, $stateParams, Data, Signup , $window) {
    $scope.user = [];
    localStorage.clear();
    $scope.error = false;
    $scope.loading = false;
    $scope.user.remember = false;
    $scope.user.comp_id = '';
    $scope.comp_id = $stateParams.comp_id;
    $rootScope.themeClass = 'blue_theme';
    $scope.user.terms = false;

    // if(angular.isUndefined($rootScope.terms)){
    //   $rootScope.terms = false;
    // }
    if($rootScope.terms == true){
      $scope.user.terms = true;
      $rootScope.terms = null;
    }

    //get current time zone
    Data.getTimezone().then(function (results) {
      $scope.timezone = results.data;
      for(i = 1; i < $scope.timezone.length; i++){
        if($scope.timezone[i].time_zone == $rootScope.ipDetails){
          $scope.user.time_zone = $scope.timezone[i].time_zone;
        }
      }
    });

    //get current country
    Data.getCountry().then(function (results) {
      $scope.country = results;
      $http.get('http://ipinfo.io/json').success(function (results) {
        $rootScope.ipDetails = results;
        $scope.user.country = $rootScope.ipDetails.country;
        $scope.Toffset = new Date().getTimezoneOffset();
      });
    });

    //register function
    $scope.doRegister = function (user) {
      $scope.loading = true;
      $http.post('/registers', {
        'company': {
          'company_name': user.CompanyName,
          'email': user.username,
          'password': user.password
        }
      }).success(function (response, error) {
        $rootScope.ipDetails = response.time_zone;
        if (response.comp_id != null) {
            $window.location.href = response.next_path ;
        } 
        else {
          $scope.error = true;
          $scope.msg = response.error;
          $timeout(function () {
            $scope.error = false
          }, 3000);
          $scope.loading = false;
        }
      });
    }
    //second step of register

    $scope.doRegisterinfo = function (user) {
      $scope.loading = true;
      $http.put('/registers/' + $scope.comp_id, {
        'company': {
          'id': $scope.comp_id,
          'first_name': user.first_name,
          'last_name': user.last_name,
          'country': user.country,
          'time_zone': user.time_zone,
          'terms': user.terms
        }
      }).success(function (response, error) {
        if (response.flag == true) {
          //$location.path("/settings/account/"+$scope.comp_id);
          //$state.go('settings/', { comp_id: $scope.comp_id});
          $state.go('settings.account', {
            comp_id: response.session_id
          });
        } 
        else {
          $scope.msg = response.error;
          $scope.error = true;
          $timeout(function () {
            $scope.error = false
          }, 3000);
          $scope.loading = false;
        }
      });
    }
  }
]);

opusSignUp.controller('TermsAndConditionCtrl', [
  '$scope',
  '$rootScope',
  '$state',
  '$stateParams',
  function ($scope, $rootScope, $state, $stateParams) {
    
    $scope.comp_id = $stateParams.comp_id;

    $scope.cancel = function(){
      $state.go('signup/:comp_id',{comp_id: $scope.comp_id});
    }

  }
]);


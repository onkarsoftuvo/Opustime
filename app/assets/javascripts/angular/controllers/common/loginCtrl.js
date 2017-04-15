var opustime_app = angular.module('Zuluapp');
opustime_app.controller('authCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$interval',
  '$state',
  '$rootScope',
  '$window' ,
  function ($scope, $location, $rootScope, $timeout, $http, $interval, $state, $rootScope , $window ) {
    $scope.user = [];
    $scope.error = false;
    $scope.loading = false;
    $scope.user.remember = false;

    $scope.home_page = function(){
      $http.get('/home_page').success(function(response){
          $window.location.href = response.login_path ;
      });
    }

    if  (($rootScope.username == 'undefined') || ($rootScope.username == null)){
        $http.get('/get_login_email').success(function(response){
            $scope.user.username = response.username ;
        });
    }

    $scope.user.username = $rootScope.username ;
    $scope.user.comp_id = $rootScope.comp_id;

    //login function
    $scope.doLogin = function (user) {
      console.log('User: ', user);
      $scope.loading = true;
      $http.post('/sign_in', {
        'email': user.username,
        'comp_id': user.comp_id,
        'password': user.password,
        'remember_me': $scope.user.remember
      }).success(function (response) {
        console.log(response);
        if (response.flag == true) {
            if (!response.is_2factor_auth_enabled) {
              $location.path('/dashboard');  
            }
            else{
              $rootScope.resendCode();
              $location.path('/loginConfirm/'+response.user_id);
            }
        }
         else if(response.flag == null) {
           $scope.msg = response.msg;
           // $scope.msg = true;
           $timeout(function () {
             $scope.msg = false;
           }, 3000);
          $scope.loading = false;
         }
        else {
          if (response.login_path == null){
              $scope.error = true;
              $timeout(function () {
                  $scope.error = false
              }, 3000);
              $scope.loading = false;
          }else {
              $window.location.href = response.login_path ;
          }

        }
             
      });
    }
    $rootScope.themeClass = 'blue_theme';
  }
]);

opustime_app.controller('authFirstCtrl' ,[ '$scope', '$http', '$state', '$timeout', '$rootScope', '$window' ,
  function($scope , $http , $state , $timeout, $rootScope , $window ){
    $scope.error = false;

    $scope.checkEmail = function(email){
        $http.get('/check_account?email=' + email).success(function(response){

            if(response.company_exist){
                if (response.count == 1 ){
                    $window.location.href = response.login_path ;
                }else{
                    $rootScope.email_id = email;
                    $state.go('login_second');  
                }
            }else{
                $scope.error = true
                $scope.errormsg = "Email doesn't exist!"
                $timeout(function(){
                    $scope.error = false
                } ,3000);
            }
        });
    }
    $scope.home_page = function(){
        $http.get('/home_page').success(function(response){
            $window.location.href = response.login_path ;
        });
    }
}]);

opustime_app.controller('authSecondCtrl' ,[ '$scope', '$http', '$rootScope', '$state', '$window', '$timeout',
  function($scope , $http, $rootScope, $state , $window , $timeout ){
    $scope.error = false;
    $scope.comp = {};
    $scope.comp.companies=[];

    $scope.home_page = function(){
          $http.get('/home_page').success(function(response){
              $window.location.href = response.login_path ;
          });
      }
      $scope.get_cookies_email = function(){
          $http.get('/get_login_email').success(function(response){
              $rootScope.email_id = response.username ;
          });
      }

      $scope.companies = function(){
        $http.get('/search_account?email='+ $rootScope.email_id).success(function(response){
            $scope.comp.companies = response.account;
        });
      }
      if ($rootScope.email_id == 'undefined' || $rootScope.email_id == null )
      {
          $scope.get_cookies_email();
          $timeout(function() {
              $scope.companies();
          } , 1500);


      }else {
          $scope.companies();
      }

    $scope.getId = function(comp){
      $rootScope.comp_id = comp.comp_id.comp_id;
      $http.get('/subdomain?comp_id='+ $rootScope.comp_id ).success(function(response){
        if (response.flag == true ){
            $rootScope.username = response.email
            localStorage.setItem('sel_comp_id',$rootScope.comp_id);
            $window.location.href = response.login_path ;
        }
      });
    }
}]);

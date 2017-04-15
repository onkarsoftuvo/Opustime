angular.module('Zuluapp').controller('loginConfirmCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$interval',
  function ($scope, $location, $rootScope, $timeout, $http, $interval) {
    $scope.error = false;
    $scope.loading = false;
    $scope.resend = false;
    $scope.resendLoading = false;
    $scope.errorMsg = '';
    //login function
    $scope.submitCode = function (code) {
      console.log(code)
      $scope.loading = true;
      $http.post('/settings/user/google_authenticator', {
        'mfa_code': code
      }).success(function (response) {
        console.log(response)
        $scope.loading = false;
        if (response.flag == true) {
          $location.path('/dashboard');
        }
        else {
          $scope.error = true;
          $scope.errorMsg = "Please enter a valid Code";
          $timeout(function () {
            $scope.error = false
          }, 3000);
          $scope.loading = false;
        }
      });
    }

    $rootScope.themeClass = 'blue_theme';
    $rootScope.resendCode = function(){
      $scope.resendLoading = true;
      console.log('resend code');
      $http.get('/settings/user/google_authenticator/resend_qr_code').success(function(result){
        $scope.resendLoading = false;
        if(result.flag){
          // $scope.resend = true;
          // $timeout(function () {
          //   $scope.resend = false
          // }, 4000);
        }
        else{
          $scope.errorMsg = "Unable to send authentication code, Please try again.";
          $scope.error = true;
          $timeout(function () {
            $scope.error = false
          }, 3000);
        }
      })
    }
    // $scope.resendCode();
  }
]);

// angular.module('Zuluapp').controller('AlertDemoCtrl', function ($scope) {
//   $scope.alerts = [
//     { type: 'danger', msg: 'Oh snap! Change a few things up and try submitting again.' },
//     { type: 'success', msg: 'Well done! You successfully read this important alert message.' }
//   ];

//   $scope.addAlert = function() {
//     $scope.alerts.push({msg: 'Another alert!'});
//   };

//   $scope.closeAlert = function(index) {
//     $scope.alerts.splice(index, 1);
//   };
// });

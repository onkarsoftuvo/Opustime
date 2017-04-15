angular.module('Zuluapp').controller('forgotPasswordCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$state',
  '$stateParams',
  'Data',
  function ($scope, $location, $rootScope, $timeout, $http, $state, $stateParams, Data) {
    $scope.originForm = angular.copy($scope.user);
    $scope.resetForm = function () {
      $scope.user = angular.copy($scope.originForm);
      $scope.ForgotPassword.$setPristine();
      $scope.ForgotPassword.$setUntouched();
    };
    //send reset password email
    $scope.SendEmail = function (user) {
      $scope.loading = true;
      $http.post('/password_resets', {
        'email': user.Email,
          'comp_id': localStorage.getItem('sel_comp_id')
      }).success(function (response) {
        if (response.flag == true) {
          $scope.Sucess = true;
          $timeout(function () {
            $scope.Sucess = false
          }, 3000);
          $scope.loading = false;
          $scope.user = {
          };
          $scope.resetForm();
        } 
        else {
          $scope.error = true;
          $timeout(function () {
            $scope.error = false
          }, 3000);
          $scope.loading = false;
          $scope.resetForm();
        }
      });
    }
  }
]);

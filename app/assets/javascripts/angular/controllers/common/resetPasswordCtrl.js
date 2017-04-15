angular.module('Zuluapp').controller('resetPasswordCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  '$state',
  '$stateParams',
  'Data',
  '$translate',
  function ($scope, $location, $rootScope, $timeout, $http, $state, $stateParams, Data, $translate) {
    $scope.loading = true;
    //get password
    $scope.GetResetPassword = function () {
      $http.get('/password_resets/' + $stateParams.id + '/edit').success(function (response) {
        if (response.password_flag == true) {
          $scope.loading = false;
        } 
        else {
          $scope.errorTokan = true;
          $timeout(function () {
            $scope.errorTokan = false
          }, 3000);
          $scope.loading = false;
        }
      });
    }
    $scope.GetResetPassword();
    $scope.originForm = angular.copy($scope.user);
    $scope.resetForm = function () {
      $scope.user = angular.copy($scope.originForm);
      $scope.ResetForm.$setPristine();
      $scope.ResetForm.$setUntouched();
    };
    //reset password
    $scope.SubmitReset = function (data) {
      $scope.loading = true;
      $http.put('/password_resets/' + $stateParams.id, {
        user: data
      }).success(function (response) {
        if (response.password_flag == true) {
          $rootScope.Sucess = true;
          $timeout(function () {
            $scope.Sucess = false
          }, 3000);
          $scope.loading = false;
          $scope.user = {
          };
          $scope.resetForm();
        } 
        else {
          $rootScope.errors = response.error;
          $rootScope.showMultyErrorToast();
          $scope.loading = false;
          $scope.resetForm();
        }
      });
    }
  }
]);

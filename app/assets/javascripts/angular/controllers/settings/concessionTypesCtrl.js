app.controller('concessionTypesCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  function ($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $modal) {
    //$scope.BtnSave = false;
    $rootScope.buttonText = 'button.update';
    $rootScope.deleteText = false;
    $rootScope.BtnSave = false;
    //Get Concession-Type list
    $rootScope.concessionList = function () {
      Data.get('/settings/concession_type').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.concessionTypes = results;
        }
      });
    }
    //For new concession

    if ($state.params.concession_id == 'new') {
      $rootScope.buttonText = 'button.save';
      $rootScope.deleteText = true;
      $rootScope.BtnSave=true;
    } 
    else if($state.params.concession_id != 'new'){
      $rootScope.buttonText = 'button.update';
      $rootScope.deleteText = false;
      $rootScope.BtnSave = true;
    }
    $rootScope.concessionList();
    //delete concession type
    $scope.conDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.concessionDelete());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
  }
]);
app.controller('concessionTypesChildCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$cookies',
  '$translate',
  function ($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $modal, $cookies, $translate) {
    //Edit Concession Type
    $scope.concessionData = function () {
      if ($state.params.concession_id != 'new') {
        Data.get('/settings/concession_type/' + $state.params.concession_id + '/edit').then(function (results) {
          if (!results.code) {
            $scope.concession = results;
          }
        });
      }
    }
    $rootScope.concessionList();
    $scope.concessionData();
    if ($state.params.concession_id == 'new') {
      $rootScope.BtnSave = true;
      $rootScope.buttonText = 'button.save';
      $rootScope.deleteText = true;
    } 
    else if($state.params.concession_id != 'new') {
      $rootScope.buttonText = 'button.update';
      $rootScope.deleteText = false;
      $rootScope.BtnSave = true;
    }
    //Create new concession

    $scope.concessionSubmit = function (data) {
      $rootScope.cloading = true;
      if ($state.params.concession_id == 'new') {
        $http.post('/settings/concession_type', data).success(function (results) {
          if (results.error) {
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
            $rootScope.cloading = false;
          } 
          else {
            $state.go('settings.discount-types.edit', {
              concession_id: results.concession_id
            });
            $translate('toast.discountCreated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.concessionList();
            $rootScope.cloading = false;
            $rootScope.BtnSave = true;
          }
        });
      } 
      else {
        $http.put('/settings/concession_type/' + $state.params.concession_id, data).success(function (results) {
          if (results.error) {
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
            $rootScope.cloading = false;
          } 
          else {
            $translate('toast.discountUpdated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.concessionList();
            $scope.concessionData();
            $rootScope.cloading = false;
          }
        });
      }
    }
    //Delete Concessions

    $rootScope.concessionDelete = function () {
      $http.delete ('/settings/concession_type/' + $state.params.concession_id).success(function (results) {
        if (results.error) {
          $rootScope.errors = results.error;
          $rootScope.showErrorToast(results.error);
          $rootScope.cloading = false;
        } 
        else {
          $scope.concessionList();
          $translate('toast.discountDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $state.go('settings.discount-types');
          $rootScope.BtnSave = false;
        }
      });
    }
  }
]);

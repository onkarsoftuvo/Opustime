app.controller('dataImportCtrl', [
  '$scope',
  '$state',
  '$http',
  '$rootScope',
  '$modal',
  function ($scope, $state, $http, $rootScope, $modal) {
    $scope.dataType = 'patient';
    //forward to upload page with data Type 
    $scope.importData = function () {
      $state.go('settings.data-imports-upload', {
        'dataType': $scope.dataType
      });
    }    //get imports list

    $rootScope.getImportList = function () {
      $rootScope.cloading = true;
      $http.get('/settings/imports').success(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        } 
        else {
          $scope.allImports = data;
        }
        $rootScope.cloading = false;
      })
    }
    $rootScope.getImportList();
    //delete import confirmation modal
    $scope.deleteImport = function (data) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteImport.html',
        controller: 'DeleteImportCtrl',
        size: 'sm',
        resolve: {
          data: function () {
            return data;
          }
        }
      });
    };
    $scope.editAgain = function (id, type) {
      $state.go('settings.data-imports-list', {
        'dataType': type,
        'importId': id
      });
    }
  }
]);
//delete modal controller
app.controller('DeleteImportCtrl', [
  '$scope',
  '$modal',
  '$modalInstance',
  'data',
  '$http',
  '$rootScope',
  '$translate',
  function ($scope, $modal, $modalInstance, data, $http, $rootScope, $translate) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }    //Delete export

    $scope.deleteImportData = function () {
      $http.delete ('/settings/imports/' + data).success(function (results) {
        $modalInstance.dismiss('cancel');
        if (results.flag) {
          $translate('controllerVeriable.importDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getImportList();
        }
      });
    }
  }
]);

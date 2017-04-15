app.controller('dataImportListCtrl', [
  '$scope',
  '$stateParams',
  'Upload',
  '$state',
  '$http',
  '$rootScope',
  '$translate',
  function ($scope, $stateParams, Upload, $state, $http, $rootScope, $translate) {
    //get dropdown attribute list
    function getList() {
      $http.get('/settings/imports/list/attributes?obj=' + $stateParams.dataType).success(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        } 
        else {
          $scope.attList = data.attributes_fields;
        }
      });
    }
    getList();
    //get doc file data
    function getImportDoc() {
      $rootScope.cloading = true;
      $http.get('/settings/imports/' + $stateParams.importId + '?obj_type=' + $stateParams.dataType).success(function (result) {
        if (!result.code) {
          $scope.importData = result.record;
          $scope.sampleLength = result.sample_len;
        }
        $rootScope.cloading = false;
      })
    }
    getImportDoc();
    //save import data into database
    $scope.saveImport = function (impData) {
      $rootScope.cloading = true;
      $scope.import = {
      };
      $scope.import.obj_type = $stateParams.dataType;
      $scope.import.data = [
      ];
      $scope.importData.forEach(function (imp) {
        if (imp.matched_column == null) {
          $scope.import.data.push('none');
        } 
        else {
          $scope.import.data.push(imp.matched_column);
        }
      })
      $scope.import = {
        'import': $scope.import
      }
      $http.put(' /settings/imports/' + $stateParams.importId, $scope.import).success(function (result) {
        $rootScope.cloading = false;
        if (result.flag) {
          $state.go('settings.data-imports');
          $translate('controllerVeriable.fileImported').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        } 
        else {
          $rootScope.errors = result.error;
          $rootScope.showMultyErrorToast();
        }
      })
    }
    $scope.goBack = function () {
      $state.go('settings.data-imports-edit', {
        'dataType': $stateParams.dataType,
        'id': $stateParams.importId
      });
    }
  }
]);

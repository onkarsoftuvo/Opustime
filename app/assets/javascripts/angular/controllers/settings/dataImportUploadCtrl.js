app.controller('dataImportUploadCtrl', [
  '$scope',
  '$stateParams',
  'Upload',
  '$state',
  function ($scope, $stateParams, Upload, $state) {
    $scope.disableSubmit = true;
    $scope.needCsvFile = false;
    //choose file
    $scope.upload = function (file) {
      $scope.fileImport = {
        'import': file
      };
      if (file) {
        $scope.uploadedName = file.name;
        var fileExtesion = $scope.uploadedName.split('.');
        if (fileExtesion[1] == 'csv' || fileExtesion[1] == 'CSV') {
          $scope.disableSubmit = false;
          $scope.needCsvFile = false;
        } 
        else {
          $scope.disableSubmit = true;
          $scope.needCsvFile = true;
        }
        $scope.fileSize = formatSizeUnits(file.size);
      }
    }    //convert bytes in desire memory unit

    function formatSizeUnits(bytes) {
      if (bytes >= 1073741824) {
        bytes = (bytes / 1073741824).toFixed(2) + ' GB';
      } 
      else if (bytes >= 1048576) {
        bytes = (bytes / 1048576).toFixed(2) + ' MB';
      } 
      else if (bytes >= 1024) {
        bytes = (bytes / 1024).toFixed(2) + ' KB';
      } 
      else if (bytes > 1) {
        bytes = bytes + ' bytes';
      } 
      else if (bytes == 1) {
        bytes = bytes + ' byte';
      } 
      else {
        bytes = '0 byte';
      }
      return bytes;
    }    //upload file

    $scope.uploadFile = function (file) {
      if ($stateParams.id) {
        Upload.upload({
          url: '/settings/imports?id=' + $stateParams.id,
          method: 'POST',
          file: file,
          data: $stateParams.dataType
        }).success(function (data, status, headers, config, evt) {
          if (data.flag) {
            $state.go('settings.data-imports-list', {
              'dataType': $stateParams.dataType,
              'importId': data.id
            });
          } 
          else if (data.error) {
            $rootScope.errors = data.error;
            $rootScope.showMultyErrorToast();
          }
        });
      } 
      else {
        Upload.upload({
          url: '/settings/imports',
          method: 'POST',
          file: file,
          data: $stateParams.dataType
        }).success(function (data, status, headers, config, evt) {
          if (data.flag) {
            $state.go('settings.data-imports-list', {
              'dataType': $stateParams.dataType,
              'importId': data.id
            });
          } 
          else if (data.error) {
            $rootScope.errors = data.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
    }
  }
]);

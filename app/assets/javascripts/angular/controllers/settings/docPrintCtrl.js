app.controller('docPrintCtrl', [
  '$scope',
  '$http',
  'Upload',
  '$rootScope',
  '$translate',
  '$state',
  function ($scope, $http, Upload, $rootScope, $translate, $state) {
    //get document data
    $scope.getDocPrint = function () {
      $http.get('/document_and_printings').success(function (details) {
        if (details.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.docprintDetails = details.document_and_printing;
          $scope.docfile = details.document_and_printing.logo;
        }
      });
    }
    $scope.getDocPrint();
    //update document
    $scope.UpdateDocPrint = function (data) {
      $rootScope.cloading = true;
      $http.put('/document_and_printings/' + data.id, {
        document_and_printing: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.getDocPrint();
          $rootScope.cloading = false;
          $translate('toast.docUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      })
    }
    //file upload for document

    $scope.docprintFileUpload = function (file) {
      Upload.upload({
        url: '/document_and_printings/' + $scope.docprintDetails.id + '/upload',
        method: 'PUT',
        file: file
      }).progress(function (evt) {
        var progressPercentage = parseInt(100 * evt.loaded / evt.total);
      }).success(function (data, status, headers, config) {
        $scope.getDocPrint();
      }).error(function (data, status, headers, config) {
      })
    };
  }
]);

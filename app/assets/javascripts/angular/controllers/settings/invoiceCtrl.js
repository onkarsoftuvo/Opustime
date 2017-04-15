app.controller('invoiceCtrl', [
  '$scope',
  '$http',
  '$rootScope',
  '$translate',
  '$state',
  function ($scope, $http, $rootScope, $translate, $state) {
    //get invoice data
    $scope.getInvoiceSettings = function () {
      $http.get('/invoice_settings').success(function (details) {
        if (details.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.invoiceSettings = details.invoice_setting;
        }
      })
    }
    $scope.getInvoiceSettings();

    //update invoice data
    $scope.UpdateInvoice = function (data) {
      $rootScope.cloading = true;
      $http.put('/invoice_settings/' + data.id, {
        invoice_setting: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.getInvoiceSettings();
          $rootScope.cloading = false;
          $translate('toast.invoiceUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }
  }
]);

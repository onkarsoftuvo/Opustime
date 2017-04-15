app.controller('InvoiceViewCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  '$http',
  'filterFilter',
  '$modal',
  'lazyload',
  '$translate',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, lazyload, $translate) {
    //To display show info
    $scope.opened = function () {
      var id = $state.params.invoice_id
      $rootScope.cloading = true;
      $http.get('/invoices/' + id).success(function (result) {
        if (result.business.country != null && result.business.country != '') {
          $scope.Jfilename = filterFilter($scope.country, {
            code: result.business.country
          });
          if ($scope.Jfilename.length) {
            Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (list) {
              $scope.state = list;
              $scope.InvoiceDetails = result;
              $rootScope.cloading = false;
            });
          } 
          else {
            $scope.InvoiceDetails = result;
            $rootScope.cloading = false;
          }
        } 
        else {
          $scope.InvoiceDetails = result;
          $rootScope.cloading = false;
        }
      });
    }
    $scope.opened();
    $scope.lazyload_config = lazyload.config();
    $rootScope.DeleteInvoice = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/invoices/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $translate('toast.invoiceDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $state.go('invoice')
        }
      })
    }
    $scope.DeleteInvoice = function (size, id, events) {
      $rootScope.pat_id = id;
      $rootScope.pat_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteInvoice($rootScope.pat_id, $rootScope.pat_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
  }
]);

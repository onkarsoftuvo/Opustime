app.controller('PaymentViewCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$stateParams',
  '$filter',
  '$translate',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $stateParams, $filter, $translate) {
    //To display show info
    $scope.opened = function () {
      var id = $state.params.payment_id
      $rootScope.cloading = true;
      $http.get('/payments/' + id).success(function (result) {
        $scope.PaymentDetails = result.payment;
        $rootScope.cloading = false;
      });
    }
    $scope.opened();
    //print payment
    $scope.PrintPayment = function (id) {
      var win = window.open('/payments/' + id + '/print.pdf', '_blank');
      win.focus();
    }
    //email account statement to patient's email

    $scope.emailPatient = function (id) {
      $rootScope.cloading = true;
      $http.get('/patients/' + id + '/send_email?email_to=patient').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      })
    }
    //Delete Payment

    $scope.PaymentDelete = function (size, id, events) {
      $rootScope.Payment_ID = id;
      $rootScope.Payment_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeletePayment($rootScope.Payment_ID, $rootScope.Payment_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $rootScope.DeletePayment = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/payments/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $scope.PaymentListData();
          $translate('toast.paymentDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }
  }
]);

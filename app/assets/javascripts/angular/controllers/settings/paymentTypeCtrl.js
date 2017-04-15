app.controller('paymentTypeCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$translate',
  function ($scope, $rootScope, $http, Data, $stateParams, $state, $modal, $translate) {
    $scope.Payment = {};
    $scope.btnpaymenttype = false;
    //Get PaymentList
    $rootScope.getpaymentList =  function () {
      $rootScope.cloading = true;
      Data.get(' /settings/payment_types').then(function (list) {
        if (list.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $rootScope.paymentList = list;
        }
        $rootScope.cloading = false;
      });
    }
    $rootScope.getpaymentList();
    $rootScope.paymentdeleteText = true;
    $rootScope.btnpaymenttype = false;
    if ($stateParams.paymentID == 'new') {
      $rootScope.btnpaymenttype = true;
      $rootScope.paymentdeleteText = true;
      $rootScope.payment_btn = 'button.save';
    } 
    else if ($stateParams.paymentID != 'new') {
      $rootScope.btnpaymenttype = true;
      $rootScope.paymentdeleteText = false;
      $rootScope.payment_btn = 'button.update';
    }

    $rootScope.deletePayment = function () {
      $rootScope.cloading = true;
      $http.delete ('/settings/payment_types/' + $state.params.paymentID).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $translate('toast.paymentTypeDeleted').then(function (msg) {
	        $rootScope.showSimpleToast(msg);
	      });
          getpaymentList();
          $state.go('settings.payment-types');
        }
      });
    }
    $scope.payDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.deletePayment());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
  }
]);


app.controller('paymentTypeInfoCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$translate',
  function ($scope, $rootScope, $http, Data, $stateParams, $state, $modal, $translate) {
    $scope.Payment = {};
    if ($stateParams.paymentID == 'new') {
      $rootScope.btnpaymenttype = true;
      $rootScope.paymentdeleteText = true;
      $rootScope.payment_btn = 'button.save';
    } 
    else if ($stateParams.paymentID != 'new') {
      $rootScope.btnpaymenttype = true;
      $rootScope.paymentdeleteText = false;
      $rootScope.payment_btn = 'button.update';
    }

    //Create new/Edit Payment_Type
    $scope.paymentSubmit = function (data) {
      $rootScope.cloading = true;
      if ($stateParams.paymentID == 'new') {
        $http.post('/settings/payment_types', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $rootScope.cloading = false;
            $translate('toast.paymentTypeCreated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
            $rootScope.getpaymentList();
            $state.go('settings.payment-types.info', {
              paymentID: results.id
            })
          }
        });
      } 
      else {
        $http.put('/settings/payment_types/' + $stateParams.paymentID, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $rootScope.cloading = false;
            $translate('toast.paymentTypeUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
           getpaymentData();
          }
        });
      }
    }
    function getpaymentData() {
      if ($stateParams.paymentID == 'new' || $stateParams.paymentID == undefined) {
      } 
      else {
        Data.get('/settings/payment_types/' + $stateParams.paymentID + '/edit').then(function (results) {
          if (!results.code) {
            $scope.Payment = results;
          }
          else{
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard');
          }
        });
      }
    }
    getpaymentData();
  }
]);

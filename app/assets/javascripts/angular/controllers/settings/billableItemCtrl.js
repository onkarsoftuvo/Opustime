app.controller('billableItemCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$modal',
  '$state',
  function ($scope, $rootScope, $http, Data, $modal, $state) {
    //get Listing OF Billable Items
    $rootScope.getBilable = function () {
      Data.get('/settings/billable_items').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.BilableItemsList = results;
        }
      });
    }
    $rootScope.getBilable();
    $rootScope.btnText = 'button.update';
    $rootScope.billdeleteText = false;
    $rootScope.btnsubmit = false;
    //delete billable items
    $scope.billDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.deleteBilable());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };

  }
]);
app.controller('billableItemChildCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$stateParams',
  '$state',
  '$translate',
  function ($scope, $rootScope, $http, Data, $stateParams, $state, $translate) {
    $scope.BilableItems = {};
    if ($stateParams.bilable_id == 'newServ' || $stateParams.bilable_id == 'new') {
      $rootScope.btnsubmit = true;
      $rootScope.btnText = 'button.save';
      $rootScope.billdeleteText = true;
    } 
    else {
      $rootScope.btnsubmit = true;
      $rootScope.btnText = 'button.update';
      $rootScope.billdeleteText = false;
    }
    function getQuickbookData() {
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/status?comp_id=' + $rootScope.User_id).success(function (results) {
        $rootScope.cloading = false;
        if (!results.code) {
          $scope.quickBookData = results;
          if (results.is_connected) {
            results.data[0].Expense[0].Name = results.data[0].Expense[0].Name + " (Default)";
          results.data[1].Income[0].Name = results.data[1].Income[0].Name + " (Default)";
          }
        }
      });
    };
    getQuickbookData();

    //get xero rate list
    /*function getXeroRates(){
      $rootScope.cloading = true;
      Data.get('/settings/billable_item/xero_info').then(function (data) {
        $scope.xeroInfo = data;
        if($scope.xeroInfo.is_connected){
          $scope.BilableItems.xero_code = "select_rate";
        }
        $rootScope.cloading = false;
      });
    };
    getXeroRates();*/
    //get tax list

    function getTaxList() {
      Data.get('/settings/tax_settings').then(function (results) {
        if (!results.code) {
          $scope.taxList = results;
          getBilableData();
        }
      });
    }
    getTaxList();
    //get billable data
    function getBilableData() {
      $rootScope.cloading = true;
      if ($stateParams.bilable_id == 'newServ' || $stateParams.bilable_id == 'new') {
        Data.get('/settings/billable_items/new').then(function (results) {
          results.tax = 'N/A'
          Data.get('/settings/concession_type').then(function (list) {
            setTimeout(function () {
              $scope.$apply(function () {
                $scope.BilableItems = results;
                if ($scope.quickBookData.is_connected) {
                  if($scope.quickBookData.data[0].selected_id == null){
                    $scope.BilableItems.expense_account_ref = $scope.quickBookData.data[0].Expense[0].id;
                  }
                  else{
                    $scope.BilableItems.expense_account_ref = $scope.quickBookData.data[0].selected_id;
                  }

                  if($scope.quickBookData.data[1].selected_id == null){
                    $scope.BilableItems.income_account_ref = $scope.quickBookData.data[1].Income[0].id;
                  }
                  else{
                    $scope.BilableItems.income_account_ref = $scope.quickBookData.data[1].selected_id;
                  }
                }
                $rootScope.cloading = false;
                $scope.$watch(function () {
                  if ($scope.BilableItems.tax && $scope.BilableItems.tax == 'N/A') {
                    $scope.BilableItems.include_tax = false;
                  }
                });
              });
            });
          })
        })
      } 
      else {
        Data.get('/settings/billable_items/' + $stateParams.bilable_id + '/edit').then(function (results) {
          //$scope.BilableItems = results;
          /*if ($scope.BilableItems.tax != 'N/A')
          $scope.BilableItems = results;
          /*if ($scope.BilableItems.tax != 'N/A')
          {
            //$scope.BilableItems.tax = parseInt($scope.BilableItems.tax);
          }*/
          setTimeout(function () {
            $scope.$apply(function () {
              $scope.BilableItems = results;
              $rootScope.cloading = false;
              $scope.$watch(function () {
                if ($scope.BilableItems.tax && $scope.BilableItems.tax == 'N/A') {
                  $scope.BilableItems.include_tax = false;
                }
              });
            });
          });
        });
      }
    }
    //Create/Edit Billable Item
    $scope.BilableSubmit = function (data) {
      /*if(data.xero_code == 'select_rate'){
        data.xero_code = null;
      }*/
      if (data.tax == '')
      {
        data.tax = 'N/A';
      }
      $rootScope.cloading = true;
      getTaxList();
      if ($stateParams.bilable_id == 'newServ' || $stateParams.bilable_id == 'new') {
        if ($stateParams.bilable_id == 'newServ') {
          data.item_type = true;
        } 
        else if ($stateParams.bilable_id == 'new') {
          data.item_type = false;
        }
        $http.post('/settings/billable_items', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.bilableCreated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.getBilable();
            $state.go('settings.billable-items.info', {
              bilable_id: results.id
            });
            $rootScope.cloading = false;
          }
        });
      } 
      else {
        // Get billable Items
        $http.put('/settings/billable_items/' + $stateParams.bilable_id, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.bilableUpdated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.getBilable();
            getBilableData();
            $rootScope.cloading = false;
          }
        });
      }
    }
    //delete bilable items

    $rootScope.deleteBilable = function () {
      $rootScope.cloading = true;
      $http.delete ('/settings/billable_items/' + $stateParams.bilable_id).success(function (results) {
        $translate('toast.bilableDeleted').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        $rootScope.getBilable();
        $state.go('settings.billable-items');
        $rootScope.cloading = false;
      });
    }
  }
]);

app.controller('taxsCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$state',
  '$translate',
  '$stateParams',
  function ($scope, $rootScope, $http, Data, $state, $translate, $stateParams) {
    //$scope.BtnTaxes = false;
    $scope.quickBookData = {};
    $scope.TaxData = {
      name: '',
      period_val: '1',
      period_name: 'days'
    };
    $rootScope.BtnTaxes = false;
    if ($stateParams.TaxID == 'new') {
      $rootScope.btnText = 'button.save';
      $rootScope.BtnTaxes = true;
    } 
    else if ($stateParams.TaxID != 'new') {
      $rootScope.btnText = 'button.update';
      $rootScope.BtnTaxes = true;
    }

    /*function getTaxData(){
      $scope.quickBookData.data.Tax.forEach(function(tax){
        if(tax.Id == $state.params.TaxID){
          $scope.TaxData.name = tax.Name;
          $scope.TaxData.amount = tax.RateValue;
        }
      })
    }*/
    $scope.connectQuickbooks = function(){
      location.href = '/settings/quickbook/authenticate?code=tax'
    }
    /*Functions*/
    //Get Taxlist

    $scope.getTaxList = function () {
      $rootScope.cloading = true;
      Data.get('/settings/tax_settings').then(function (list) {
        if (list.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $rootScope.TaxList = list;
        }
        $rootScope.cloading = false;
      });
    }

    $scope.syncTaxes = function(){
      $rootScope.cloading = true;
      Data.get('/settings/quickbook/sync_taxes').then(function (list) {
        console.log(list)
        //$rootScope.TaxList = list;
        $scope.quickBookData = list;
        $rootScope.cloading = false;
      });
    }

    $scope.getTaxData = function () {
      $rootScope.cloading = true;
      console.log($scope.quickBookData);
      if ($stateParams.TaxID == 'new') {
        $scope.TaxData = {
          name: '',
          amount: '0',
        };
        if ($scope.quickBookData.is_connected) {
          $scope.TaxData.tax_code_ref = $scope.quickBookData.data.selected_id;
        }
        $rootScope.cloading = false;
      }
      else if ($stateParams.TaxID != 'new' && $stateParams.TaxID != undefined) {
        $rootScope.btnText = 'button.update';
        Data.get('/settings/tax_settings/' + $stateParams.TaxID + '/edit').then(function (data) {
          if (!data.code) {
            $scope.TaxData = data;
          }
          $rootScope.cloading = false;
        });
      }
      $rootScope.cloading = false;
    }
    $scope.getTaxList();

    function getQuickbookData() {
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/status?code=tax&comp_id=' + $rootScope.User_id).success(function (results) {
        console.log(results);
        $rootScope.cloading = false;
        if (!results.code) {
          $scope.quickBookData = results;
          $scope.getTaxData();
          if ($state.params.TaxID) {
            //getTaxData();
          }
        }
      });
    };
    getQuickbookData();

    //Create new/Edit Tax 
    $scope.TaxSubmit = function (data) {
      if(data.xero_rate == 'select_rate'){
        data.xero_rate = null
      }
      console.log(data);
      $rootScope.cloading = true;
      if ($state.params.TaxID == 'new') {
        $http.post('/settings/tax_settings', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $state.go('settings.taxes.info', {
              TaxID: results.id
            });
            $rootScope.btnText = 'button.update';
            $translate('toast.taxTypeCreated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.getTaxList();
            $rootScope.cloading = false;
          }
        });
      } 
      else if ($stateParams.TaxID != 'new') {
        if(data.xero_rate == 'select_rate'){
          data.xero_rate = null
        }
        $rootScope.btnText = 'button.update';
        $http.put('/settings/tax_settings/' + $state.params.TaxID, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.taxTypeUpdated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.getTaxList();
            $rootScope.cloading = false;
          }
        });
      }
    }
    //Delete Tax

    $rootScope.DeleteTax = function (data) {
      $rootScope.cloading = true;
      $http.delete ('/settings/tax_settings/' + $state.params.TaxID).success(function (results) {
        $state.go('settings.Tax-types');
        $translate('toast.taxTypeDeleted').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        $scope.getTaxList();
        $rootScope.cloading = false;
      });
    }
  }
]);

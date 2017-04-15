app.controller('add_edit_ExpenseCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$filter',
  '$timeout',
  '$translate',
  '$stateParams',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $filter, $timeout, $translate, $stateParams) {
    $scope.NewExpenses = {};
    $scope.hv_next_pre = false;
    $scope.editEx = false;
    $scope.maxDate = new Date();
    $scope.today = function () {
      $scope.NewExpenses.expense_date = new Date();
    };
    $scope.today();
    $scope.open = function ($event) {
      $scope.status.opened = true;
    };
    $scope.status = {
      opened: false
    };
    $scope.header = {
      module:'controllerVeriable.expense',
      title:'controllerVeriable.newExpense',
      back_link: 'expense',
    }
    

    //add new expence product into array
    $scope.addExpenseProduct = function () {
      $scope.NewExpenses.expense_products_attributes.push({
        name: '',
        unit_cost_price: '',
        quantity: '',
        prod_id: ''
      });
    };
    //remove expence product from array
    $scope.removeExpenseProduct = function (index) {
      $scope.NewExpenses.expense_products_attributes.splice(index, 1);
    };

    $scope.createEdit = true;
    $scope.hitExp.then(function(greeting){
      if(!$stateParams.ex_id){
        if(!$rootScope.expPerm.create){
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
      }
      else{
        if (!$rootScope.expPerm.modify) {
          $scope.createEdit = false;
        }
      }
    });

    //calculate tax
    $scope.CalculateTax = function () {
      if ($scope.NewExpenses.tax) {
        $scope.TaxIndex = filterFilter($scope.taxList, {
          id: $scope.NewExpenses.tax
        });
        if ($scope.NewExpenses.total_expense != undefined && $scope.NewExpenses.total_expense != '')
        {
          $scope.NewExpenses.tax_amount = parseFloat($scope.NewExpenses.total_expense - ($scope.NewExpenses.total_expense) / (1 + ($scope.TaxIndex[0].amount / 100))).toFixed(2);
        } 
        else
        {
          $scope.NewExpenses.tax_amount = '';
        }
      } 
      else {
        $scope.NewExpenses.tax_amount = '';
      }
    }
    //Get category data
    $scope.getCategoryData = function () {
      $http.get('/expenses/categories').success(function (data) {
        $scope.categoryData = data;
      });
    }
    $scope.getCategoryData();
    $scope.getCategoryDataf = function (query) {
      $scope.categoryFind = query;
      query = angular.lowercase(query)
      return $filter('filter') ($scope.categoryData, query)
    }

    //Get category data
    $scope.getVendorData = function () {
      $http.get('/expenses/vendors').success(function (data) {
        $scope.vendorData = data;
      });
    }
    $scope.getVendorData();
    $scope.getVendorDataf = function (query) {
      $scope.vendorFind = query;
      query = angular.lowercase(query)
      return $filter('filter') ($scope.vendorData, query)
    }

    //create new expanse
    $scope.CreateExpenses = function (data) {
      $rootScope.cloading = true;
      if ($stateParams.ex_id) {
        $scope.UpdateExpenses(data);
      }
      else{
        if(data.category == null){
        data.category = {};
        $scope.categoryData.forEach(function(cat){
          if(cat.name == $scope.categoryFind){
            data.category.name = cat.name;
            data.category.id = cat.id;
          }
        })
        if(angular.equals({}, data.category)){
          data.category.name =$scope.categoryFind;
        }
      }
      if(data.vendor == null){
        data.vendor = {};
        $scope.vendorData.forEach(function(van){
          if(van.name == $scope.vendorFind){
            data.vendor.name = van.name;
            data.vendor.id = van.id;
          }
        })
        if(angular.equals({}, data.vendor)){
          data.vendor.name =$scope.vendorFind;
        }
      }
        $rootScope.cloading = true;
        for (var i = 0; i < data.expense_products_attributes.length; i++) {
          if (data.expense_products_attributes[i].name != null)
          {
            if (data.expense_products_attributes[i].name.prod_id != '')
            {
              data.expense_products_attributes[i].prod_id = data.expense_products_attributes[i].name.prod_id;
              data.expense_products_attributes[i].name = data.expense_products_attributes[i].name.name;
            }
          }
        }
        $http.post('/expenses', {
          expense: data
        }).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $rootScope.cloading = false;
            $translate('toast.expenseAdded').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $state.go('expense',{}, { reload: true});
            // $state.go('expense');
            // $scope.$parent.getExpenseList();
          }
        });
      }
    }

    //get tax list
    $scope.getTaxList = function () {
      $http.get('/settings/tax_settings').success(function (taxList) {
        $scope.taxList = taxList;
      });
    }
    $scope.getTaxList();

    //get bussiness list
    $scope.getBusinessList = function () {
      Data.get('/settings/business').then(function (results) {
        $rootScope.cloading = false;
        $scope.businessList = results;
        $scope.NewExpenses.business_name = '' + $scope.businessList[0].id;
      });
    }
    $scope.getBusinessList();
    //get product list
    $scope.getProductList = function () {
      $http.get('/expense/list/products').success(function (list) {
        $scope.ProductsList = list;
      });
    }
    $scope.getProductList();
    $scope.ProductsListf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.ProductsList, query)
    }

    //hit when trying to add a new axpanse
    $scope.new_exp = function () {
      $scope.NewExpenses = {
        tax: '',
        include_product_price: 'false',
        expense_date: $scope.NewExpenses.expense_date,
        expense_products_attributes: [
          {
            name: '',
            unit_cost_price: '',
            quantity: '',
            prod_id: ''
          }
        ]
      };
    }
    $scope.new_exp();

    $scope.editExpense = function (id) {
      $rootScope.cloading = true;
      $http.get(' /expenses/' + id + '/edit').success(function (results) {
        $scope.ExpenseDetail = results;
        $scope.NewExpenses = $scope.ExpenseDetail;
        $scope.NewExpenses.include_product_price = '' + $scope.ExpenseDetail.include_product_price;
        for (var i = 0; i < $scope.NewExpenses.expense_products_attributes.length; i++) {
          $scope.NewExpenses.expense_products_attributes[i].name = {
            name: $scope.NewExpenses.expense_products_attributes[i].name,
            prod_id: $scope.NewExpenses.expense_products_attributes[i].prod_id
          }
        }
        $rootScope.cloading = false;
      });
    }

    function getQuickbookData() {
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/expense_accounts?comp_id=' + $rootScope.User_id).success(function (results) {
        $rootScope.cloading = false;
        $scope.quickBookData = results;
        if (results.is_connected) {
          results.data[0].Expense[0].Name = results.data[0].Expense[0].Name + " (Default)";
          if(results.data[0].selected_id == null){
            $scope.NewExpenses.expense_account_ref = results.data[0].Expense[0].id;
          }
          else{
            $scope.NewExpenses.expense_account_ref = results.data[0].selected_id;
          }
        }
        if($stateParams.ex_id){
          $scope.header.title = 'controllerVeriable.editExpense';
          $scope.editEx = true;
          $scope.hv_next_pre = true;
          $scope.editExpense($stateParams.ex_id)
        }
      });
    };
    getQuickbookData();
    //update expense
    $scope.UpdateExpenses = function (data) {
      $rootScope.cloading = true;
      if(data.category == null){
        data.category = {};
        $scope.categoryData.forEach(function(cat){
          if(cat.name == $scope.categoryFind){
            data.category.name = cat.name;
            data.category.id = cat.id;
          }
        })
        if(angular.equals({}, data.category)){
          data.category.name =$scope.categoryFind;
        }
      }
      if(data.vendor == null){
        data.vendor = {};
        $scope.vendorData.forEach(function(van){
          if(van.name == $scope.vendorFind){
            data.vendor.name = van.name;
            data.vendor.id = van.id;
          }
        })
        if(angular.equals({}, data.vendor)){
          data.vendor.name =$scope.vendorFind;
        }
      }
      $rootScope.cloading = true;
      for (var i = 0; i < data.expense_products_attributes.length; i++) {
        if (data.expense_products_attributes[i].name != null)
        {
          if (data.expense_products_attributes[i].name.prod_id != '')
          {
            data.expense_products_attributes[i].prod_id = data.expense_products_attributes[i].name.prod_id;
            data.expense_products_attributes[i].name = data.expense_products_attributes[i].name.name;
          }
        }
      }
      $http.put('expenses/' + data.id, {
        expense: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          // $state.go('expense');
          // $scope.$parent.getExpenseList();
          $state.go('expense',{}, { reload: true});
          $rootScope.cloading = false;
          $translate('toast.expenseUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }  

    //hit cancel
    $scope.hitCancel = function(){
      $state.go('expense');
    }
  }
]);

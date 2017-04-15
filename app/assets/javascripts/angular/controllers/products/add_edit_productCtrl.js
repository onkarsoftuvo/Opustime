app.controller('add_edit_productCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$timeout',
  '$translate',
  'Data',
  '$stateParams',
  function ($rootScope, $scope, $state, $http, $modal, $timeout, $translate, Data, $stateParams) {
    $scope.product = {};
    $scope.editProduct = false;

    //tabbing setting
    $scope.editPro = true;
    $scope.stockAdjust = false;
    $scope.stockAdjustForm = false;

    $scope.openStockTable = function(){
      $scope.editPro = false;
      $scope.stockAdjust = true;
      $scope.stockAdjustForm = false;
    }
    $scope.openProduct = function(){
      $scope.editPro = true;
      $scope.stockAdjust = false;
      $scope.stockAdjustForm = false;
    }
    $scope.openStock = function(){
      $scope.editPro = false;
      $scope.stockAdjust = false;
      $scope.stockAdjustForm = true;
    }
    
    $scope.header = {
      module:'controllerVeriable.product',
      title:'controllerVeriable.newProduct',
      back_link: 'products',
    }
    
    
    //get tax list
    $scope.getTaxList = function () {
      $http.get('/settings/tax_settings').success(function (taxList) {
        $scope.taxList = taxList;
      });
    }
    $scope.getTaxList();

    $scope.Stock = {
      stock_level: 'increasing'
    };

    $scope.editProd = function (id) {
      $rootScope.cloading = true;
      $http.get('/products/' + id + '/edit').success(function (data) {
        $scope.product = data;
        $rootScope.cloading = false;
        if ($scope.product.stock_number == null) {
          $scope.showStocktext = false;
        }
        else{
          $scope.showStocktext = true;
        }
      });
    }
    $scope.createEdit = true;
    $scope.hitPer.then(function(greeting){
      if(!$stateParams.pro_id){
        if(!$rootScope.proPerm.create){
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
      }
      else{
        if (!$rootScope.proPerm.modify) {
          $scope.createEdit = false;
        }
      }
    });


    $scope.getStockList = function (id) {
      $http.get('/products/' + id + '/product_stocks').success(function (product_stocks) {
        $scope.ProductStocks = product_stocks.product_stocks;
        $rootScope.cloading = false;
      });
    }
    function getQuickbookData() {
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/status?comp_id=' + $rootScope.User_id).success(function (results) {
        $rootScope.cloading = false;
        $scope.quickBookData = results;

        if (results.is_connected) {
          results.data[0].Expense[0].Name = results.data[0].Expense[0].Name + " (Default)";
          results.data[1].Income[0].Name = results.data[1].Income[0].Name + " (Default)";
          if(results.data[0].selected_id == null){
            $scope.product.expense_account_ref = results.data[0].Expense[0].id;
          }
          else{
            $scope.product.expense_account_ref = results.data[0].selected_id;
          }

          if(results.data[1].selected_id == null){
            $scope.product.income_account_ref = results.data[1].Income[0].id;
          }
          else{
            $scope.product.income_account_ref = results.data[1].selected_id;
          }
        }
        if($stateParams.pro_id){
          $scope.header.title = 'Edit Product';
          $scope.editProduct = true;
          $scope.hv_next_pre = true;
          $scope.editProd($stateParams.pro_id);
          $scope.getStockList($stateParams.pro_id);
        }
      });
    };
    getQuickbookData();

    $scope.resetButton = function(data){
      if (data == '') {
        $scope.product.include_tax = false;  
      }
    }

    

    //edit product
    $scope.EditProduct = function (index) {
      $scope.editProduct = true;
      $scope.stockadjustment = false;
      $scope.stockadjustmentEdit = false;
      $scope.getTaxList();
      if ($scope.ProductsList[index].stock_number == null) {
        $scope.showStocktext = false;
      } 
      else if ($scope.ProductsList[index].stock_number != null) {
        $scope.showStocktext = true;
      }
    }
    $scope.EditStock = function (index) {
      $scope.editProduct = false;
      $scope.stockadjustment = false;
      $scope.stockadjustmentEdit = true;
      $scope.Stock = {};
      $scope.Stock = {
        stock_level: 'increasing',
        stock_type: 'Stock Purchase'
      };
    }
    //update product

    $scope.UpdateProduct = function (data) {
      $rootScope.cloading = true;
      $http.put('/products/' + data.id, {
        product: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          // $scope.$parent.getProductList();
          // $state.go('products');
          $state.go('products',{}, { reload: true });
          $translate('toast.productUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
        }
      })
    }
    //update stock

    $scope.UpdateStock = function (data, id) {
      $rootScope.cloading = true;
      $http.post('/products/' + id + '/product_stocks', {
        product_stock: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          // $scope.$parent.getProductList();
          $scope.Stock.quantity = '';
          $scope.editPro = false;
          $scope.stockAdjust = true;
          $scope.stockAdjustForm = false;
          $rootScope.cloading = false;
          $scope.editProd($stateParams.pro_id);
          $scope.getStockList($stateParams.pro_id);
          $translate('toast.stockUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      })
    }


    //add new product
    $scope.AddProduct = function (data) {
      if($stateParams.pro_id){
        $scope.UpdateProduct(data);
      }
      else{
        $rootScope.cloading = true;
        $scope.new_product = true;
        $http.post('/products', {
          product: data
        }).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            // $scope.$parent.getProductList();
            // $state.go('products');
            $state.go('products',{}, { reload: true });
            $translate('toast.productAdded').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.cloading = false;
          }
        })
      }
    }
    //$scope.originForm = angular.copy($scope.product);
    //reset form
    /*$scope.resetForm = function () {
      $scope.product = angular.copy($scope.originForm);
      $scope.$$childTail.productForm.$setPristine();
      $scope.$$childTail.productForm.$setUntouched();
    };*/
    //hit cancel
    $scope.hitCancel = function(){
      $state.go('products');
    }
  }
]);


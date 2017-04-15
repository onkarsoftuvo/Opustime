app.controller('productCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$timeout',
  '$translate',
  'Data',
  '$q',
  'pageService',
  function ($rootScope, $scope, $state, $http, $modal, $timeout, $translate, Data, $q, pageService) {
    init();

    function init(){
      $scope.pagingData = {};
      $scope.pagingData.fromFilter = '',
      $scope.pagingData.toFilter = '',
      $scope.pagingData.Page = 1;
      $scope.pagingData.TotalItems = 0;
      $scope.pagingData.PageSize = 30;
      $scope.showGrid = false;
    }

    $scope.product = {};
    $scope.disable_search = false;
    $scope.new_product = false;
    $scope.AddProductBtn = true;
    $scope.Addproduct = false;
    //hit when trying to add new product
    $scope.AddProduct = function(){
      $state.go('products.new');
    }
    $scope.editProduct = function(id){
      $state.go('products.edit', {'pro_id': id});
    }
    $scope.AddProductshow = function () {
      $scope.new_product = true;
      $scope.AddProductBtn = false;
      $scope.SaveCancelBtn = true;
      $scope.Addproduct = true;
      $scope.noRecordFount = false;
      $scope.noModule = false;
      $scope.product = {};
      //$scope.product.xero_code = "select_rate";
    }
    //hit when cancel to add new product

    $scope.AddProductHide = function () {
      $scope.new_product = false;
      $scope.AddProductBtn = true;
      $scope.SaveCancelBtn = false;
      $scope.Addproduct = false;
      $scope.noRecordFount = false;
      if ($scope.noData == true) {
        $scope.noModule = true;
      }
    }
    //delete product

    $scope.productDelete = function (size, id, events) {
      $rootScope.pro_id = id;
      $rootScope.pro_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        controller: 'deleteProductCtrl',
        size: size,
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteProduct($rootScope.pro_id, $rootScope.pro_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $scope.pagging = [];
    $scope.noModule = false;
    /*//get xero rate list
    function getXeroRates(){
      $rootScope.cloading = true;
      Data.get('/products/xero_info').then(function (data) {
        $scope.accCode = data;
        $rootScope.cloading = false;
      });
    };
    getXeroRates();*/

    $scope.productLogs = function(pagingData) {
      $scope.ProductsList = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/products?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = $http.get('/products?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.success(function(list){
        if(list.product.length != 0){
          for (var i = 0; i < list.product.length; i++) {
            list.product[i].isopen = false;
          }
          $scope.ProductsList = list.product;
          $scope.ProductsDetail = list;
          $scope.pagingData.TotalItems = list.total;
          $scope.showGrid = true;
          $scope.noRecordFount = false;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
      });
    }
    
    //get product list
    // $scope.getProductList = function () {
    //   $http.get('/products').success(function (list) {
    //     console.log(list)
    //     if (list.product) {
    //       $scope.ProductsList = list.product;
    //         $scope.ProductsDetail = list;
    //         if ($scope.ProductsList.length == 0) {
    //           $scope.noModule = true;
    //           $scope.noData = true;
    //         }
    //         else{
    //           $scope.noModule = false;
    //           $scope.noData = false;
    //         }
    //         for (var i = 0; i < list.product.length; i++) {
    //           list.product[i].isopen = false;
    //         }
    //         $scope.pagging = [];
    //         for (i = 1; i <= $scope.ProductsDetail.pagination.total_pages; i++) {
    //           $scope.pagging.push({
    //             pageNo: i
    //           });
    //         }
    //     }
    //   });
    // }
    //get tax list

    $scope.getTaxList = function () {
      $http.get('/settings/tax_settings').success(function (taxList) {
        $scope.taxList = taxList;
      });
    }
    
    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/products/security_roles').success(function(data){
          console.log(data);
          $rootScope.proPerm = data;
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')  
          }
          else{
            // $scope.getProductList();
            $scope.productLogs($scope.pagingData);
          }
          resolve();
        });
      });
    }
    $scope.hitPer = getPermissions();


    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.productLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };

    //pagination ends here----------------------------------------------------

    //Clear products logs
    $scope.clearLogs = function() {
      $scope.pagingData.fromFilter = "";
      $scope.productLogs($scope.pagingData); 
    }

    //filter for product search list

    // $scope.noRecordFount = false;
    // var _timeout;
    // $scope.productSearch = function (Term) {
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     $http.get('/products?q=' + Term).success(function (data) {
    //       $scope.ProductsList = data.product;
    //       $scope.ProductsDetail = data;
    //       if ($scope.ProductsList.length == 0) {
    //         $scope.noRecordFount = true;
    //         $scope.noModule = false;
    //       } 
    //       else {
    //         $scope.noRecordFount = false;
    //       }
    //       $rootScope.cloading = false;
    //     });
    //     _timeout = null;
    //   }, 1000);
    // }
    //show inner data of product

    $scope.showProductDetails = function (index) {
      if ($scope.ProductsList[index].isopen) {
        return true;
      }
    }
    $scope.Stock = {
      stock_level: 'increasing'
    };
    $scope.opened = function (index, id) {
      setTimeout(function () {
        if ($scope.ProductsList[index].isopen) {
          $scope.stockadjustment = true;
          $scope.editProduct = false;
          $scope.stockadjustmentEdit = false;
          $scope.getTaxList();
          $http.get('/products/' + id + '/product_stocks').success(function (product_stocks) {
            $scope.ProductStocks = product_stocks.product_stocks;
            $rootScope.cloading = false;
          });
        }
      })
    }
    //edit product
    $scope.EditProdcut = function (index) {
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
    $scope.backToStock = function () {
      $scope.getProductList();
      $scope.editProduct = false;
      $scope.stockadjustmentEdit = false;
      $scope.stockadjustment = true;
    }
    //update product

    $scope.UpdateProduct = function (data, id) {
      $rootScope.cloading = true;
      $http.put('/products/' + id, {
        product: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.getProductList();
          $translate('toast.productUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
        }
      })
    }
    //update stock

    $scope.UpdateStock = function (data, id) {
      $http.post('/products/' + id + '/product_stocks', {
        product_stock: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.getProductList();
          $translate('toast.stockUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
        }
      })
    }
    //delete product

    $rootScope.DeleteProduct = function (id, e) {
      $rootScope.cloading = true;
      e.preventDefault();
      e.stopPropagation();
      $http.delete ('/products/' + id, {
        status: false
      }).success(function (results) {
         $rootScope.cloading = false;
        if (results.error) {
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.productLogs($scope.pagingData);
          $translate('toast.productDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
         
        }
      })
    }
    $scope.getTaxList();
    //add new product
    $scope.AddProduct = function (data) {
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
          $scope.resetForm();
          $scope.noData = false;
          $scope.Addproduct = false;
          $translate('toast.productAdded').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $state.go('products.list');
          $rootScope.cloading = false;
          $scope.getProductList();
          $scope.new_product = false;
          $scope.AddProductBtn = true;
          $scope.SaveCancelBtn = false;
          $scope.product = '';
        }
      })
    }
    $scope.originForm = angular.copy($scope.product);
    //reset form
    $scope.resetForm = function () {
      $scope.product = angular.copy($scope.originForm);
      $scope.$$childTail.productForm.$setPristine();
      $scope.$$childTail.productForm.$setUntouched();
    };
  }
]);

//Product List Controller
app.controller('productListCtrl', [
  function () {
  }
]);
//delete product controller
app.controller('deleteProductCtrl', [
  function () {
  }
]);

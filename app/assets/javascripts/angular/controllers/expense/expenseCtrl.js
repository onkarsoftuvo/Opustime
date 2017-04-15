app.controller('expenseCtrl', [
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
  '$q',
  'pageService',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $filter, $timeout, $translate, $q, pageService) {
    
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

    $scope.exp_detail = true;
    $scope.selectedItem = null;
    $scope.searchText = null;
    $scope.selectedItemp = null;
    $scope.searchTextp = null;
    $scope.ExpenseDetails = true;
    $scope.edit_bar = false;
    $scope.SaveExpenseBtn = true;
    $scope.show_edit_Expense = function () {
      $scope.ExpenseDetails = false;
      $scope.edit_bar = true;
    }

    //delete expense
    $scope.expenseDelete = function (size, id, events) {
      $rootScope.exp_id = id;
      $rootScope.exp_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        controller: 'deleteExpenseCtrl',
        size: size,
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteExpense($rootScope.exp_id, $rootScope.exp_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };

    //delete expanse
    $rootScope.DeleteExpense = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/expenses/' + id).success(function (results) {
        if (results.flag) {
          $scope.businessInfo = results.data;
          $scope.getExpenseList();
          $rootScope.cloading = false;
          $translate('toast.expenseDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        } 
        else {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
      });
    }
    
    $scope.pagging = [];
    $scope.noModule = false;
    //get expense list
    // $scope.getExpenseList = function () {
    //   $http.get('/expenses').success(function (list) {
    //     for (var i = 0; i < list.expense.length; i++) {
    //       list.expense[i].isopen = false;
    //     }
    //     $scope.ExpenseList = list.expense;
    //     $scope.ExpenseDetail = list;
    //     if ($scope.ExpenseList.length == 0) {
    //       $scope.noModule = true;
    //       $scope.noData = true;
    //     }
    //     else{
    //       $scope.noModule = false;
    //       $scope.noData = false;
    //     }
    //     $scope.pagging = [];
    //     for (i = 1; i <= $scope.ExpenseDetail.pagination.total_pages; i++) {
    //       $scope.pagging.push({
    //         pageNo: i
    //       });
    //     }
    //   });
    // }

    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/expenses/security_roles').success(function(data){
          console.log(data);
          $rootScope.expPerm = data;
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')  
          }
          else{
            // $scope.getExpenseList();
            $scope.expenseLogs($scope.pagingData);
          }
          resolve();
        });
      });
    }
    $scope.hitExp = getPermissions();

    //get expense list
    $scope.expenseLogs = function(pagingData) {
      $scope.ExpenseList = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/expenses?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = $http.get('/expenses?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.success(function(list){
        if(list.expense.length != 0){
          for (var i = 0; i < list.expense.length; i++) {
            list.expense[i].isopen = false;
          }
          $scope.ExpenseList = list.expense;
          $scope.ExpenseDetail = list;
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

    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.expenseLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };

    //pagination ends here----------------------------------------------------

    //Clear expense logs
    $scope.clearLogs = function() {
      $scope.pagingData.fromFilter = "";
      $scope.expenseLogs($scope.pagingData); 
    }
    
    //filter for expense search list

    // $scope.noRecordFount = false;
    // var _timeout;
    // $scope.expenseSearch = function (Term) {
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     $http.get('/expenses?q=' + Term).success(function (data) {
    //       $scope.ExpenseList = data.expense;
    //       $scope.ExpenseDetail = data;
    //       if ($scope.ExpenseList.length == 0) {
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

    $scope.editExpense = function(id){
      $state.go('expense.edit', {'ex_id' : id})
    }

    //show inner detail of an expense
    $scope.showExpenseDetails = function (index) {
      if ($scope.ExpenseList[index].isopen) {
        return true;
      }
    }

    $scope.opened = function (index, id) {
      setTimeout(function () {
        if ($scope.ExpenseList[index].isopen) {
          $rootScope.cloading = true;
          $http.get(' /expenses/' + id + '/edit').success(function (results) {
            $scope.ExpenseDetail = results;
            $rootScope.cloading = false;
          });
          $scope.ShowEditExpense = false;
          $scope.exp_detail = false;
          $scope.ExpenseDetails = true;
          $scope.edit_bar = false;
        } 
        else if (!$scope.ExpenseList[index].isopen) {
          $scope.ExpenseDetail = '';
        }
      })
    }

    //edit an expense
    $scope.sEditExpense = function (index, id) {
      if ($scope.ExpenseList[index].isopen) {
        $scope.ExpenseDetails = false;
        $scope.exp_detail = false;
        $scope.edit_bar = true;
        $scope.NewExpenses = $scope.ExpenseDetail;
        $scope.NewExpenses.include_product_price = '' + $scope.ExpenseDetail.include_product_price;
        for (var i = 0; i < $scope.NewExpenses.expense_products_attributes.length; i++) {
          $scope.NewExpenses.expense_products_attributes[i].name = {
            name: $scope.NewExpenses.expense_products_attributes[i].name,
            prod_id: $scope.NewExpenses.expense_products_attributes[i].prod_id
          }
        }
      }
    }
  }
]);

app.controller('deleteExpenseCtrl', [
  function () {
  }
]);

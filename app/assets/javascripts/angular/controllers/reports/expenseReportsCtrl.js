app.controller('expenseReportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$http',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $http, $state) {
    //$scope.activeBtn = 0;
    $scope.$state = $state;
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.noData = false;
    $scope.noSummary = false;
    $scope.filter = {};
    $scope.filter.category = 'all';
    $scope.filter.to = new Date();
    var curDate = new Date();
    $scope.filter.from = new Date(curDate.getFullYear(), curDate.getMonth(), 1);
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    
    //onload table content data
    $scope.allExpensesData = function () {
      $rootScope.cloading = true;
      $scope.filterData = {};
      $scope.filterData.start_date = $scope.filter.from;
      $scope.filterData.end_date = $scope.filter.to;
      $scope.filterData.category = $scope.filter.category;
      var startDate = $scope.filter.from.getDate() + '/' + ($scope.filter.from.getMonth()+1) + '/' + $scope.filter.from.getFullYear();
      var endDate = $scope.filter.to.getDate() + '/' + ($scope.filter.to.getMonth()+1) + '/' + $scope.filter.to.getFullYear();
      $http.get('/expense_reports/listing?start_date='+ startDate + '&end_date='+ endDate + '&category=' + $scope.filterData.category).success(function (data) {
        console.log(data);
        if (data.list) {
          $scope.allExpensesList = data.list;
          if($scope.allExpensesList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false; 
          }
        }
        if (data.summary) {
          $scope.allSummary = data.summary;
          if ($scope.allSummary.length == 0) {
            $scope.noSummary = true;
          }
          else{
            $scope.noSummary = false;
          }
        }
        if (data.summary_total) {
          $scope.summaryTotal = data.summary_total[0];
        }
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard') 
        }
        $rootScope.cloading = false;
      });
    }

    //get all categories
    function allCategory(){
      Data.get('/expense_reports/categories').then(function(data){
        $scope.allCategoryList = data;
        $scope.allExpensesData();
      })
    }
    allCategory();
    
    //export data
    $scope.export = function(){
      $scope.filterData = {};
      $scope.filterData.start_date = $scope.filter.from;
      $scope.filterData.end_date = $scope.filter.to;
      $scope.filterData.category = $scope.filter.category;
      var startDate = $scope.filter.from.getDate() + '/' + ($scope.filter.from.getMonth()+1) + '/' + $scope.filter.from.getFullYear();
      var endDate = $scope.filter.to.getDate() + '/' + ($scope.filter.to.getMonth()+1) + '/' + $scope.filter.to.getFullYear();
      var win = window.open('/expense_reports/listing/export.csv?start_date='+ startDate + '&end_date='+ endDate + '&category=' + $scope.filterData.category, '_blank');
    }
  }
]);

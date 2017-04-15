app.controller('smsLogsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$http',
  '$state',
  'pageService',
  '$window',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $http, $state, pageService, $window) {
    $scope.from = {open: false};
    $scope.to = {open: false};
    $scope.logs = [];
    // $scope.filter = {};
    init();

    function init(){
      $scope.pagingData = {};
      $scope.pagingData.fromFilter = '';
      $scope.pagingData.toFilter = '';
      $scope.pagingData.user_id = null;
      $scope.pagingData.Page = 1;
      $scope.pagingData.TotalItems = 0;
      $scope.pagingData.PageSize = 30;
      $scope.showGrid = false;
    }

    $scope.openFrom = function ($event) {
      $scope.from.open = true;
    };

    $scope.openTo = function ($event) {
      $scope.to.open = true;
    };

    // $scope.getLogs = function(){
    //   $rootScope.cloading = true;
    //   $http.get('/sms_center/logs').success(function (data) {
    //     $rootScope.cloading = false;
    //     $scope.pagingData.from = '';
    //     $scope.pagingData.to = '';
    //     if(data.logs.length != 0){
    //       $scope.showGrid = true;
    //       $scope.logs = data;
    //       $scope.pagingData.TotalItems = data.total;
    //       setPager();
    //     }else{
    //       $scope.showGrid = false;
    //     }
    //     // $scope.pagging = [];
    //     // for (i = 1; i <= $scope.logs.pagination.total_pages; i++) {
    //     //   $scope.pagging.push({
    //     //     pageNo: i
    //     //   });
    //     // }
    //   });
    // }
    
    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/communications/check/security_roles').success(function(data){
          console.log(data);
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')  
          }
          else{
            $scope.filterLogs($scope.pagingData);
          }
          resolve();
        });
      });
    }
    $scope.hitCom = getPermissions();

    $scope.selectAll = function (status) {
      if (status) {
        $scope.logs.forEach(function (log) {
          log.isSelect = true;
        });
      }
      else{
        $scope.logs.forEach(function (log) {
          log.isSelect = false;
        }); 
      }
    };

    $scope.filterLogs = function(pagingData) {
      $scope.logs = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id == null) {
        obj = $http.get('/sms_center/logs?per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
      }else if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id != null){
        obj = $http.get('/sms_center/logs?per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page + '&user_id=' + pagingData.user_id);
      }else if(pagingData.toFilter !="" && pagingData.fromFilter != "" && pagingData.user_id == null){
        obj = $http.get('/sms_center/logs?start_date=' + $scope.pagingData.fromFilter + '&end_date=' + $scope.pagingData.toFilter + '&per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
      }else{
        obj = $http.get('/sms_center/logs?start_date=' + $scope.pagingData.fromFilter + '&end_date=' + $scope.pagingData.toFilter + '&per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page + '&user_id=' + pagingData.user_id);
      }
      obj.success(function(data){
        if(data.logs.length != 0){
          $scope.showGrid = true;
          $scope.logs = data;
          $scope.allUsers = data.all_users;
          $scope.pagingData.TotalItems = data.total;
          setPager();
        }else{
          $scope.showGrid = false;
        }
      });
    }

    $scope.clearLogs = function(pagingData) {
      // $scope.pagingData = {};
      pagingData.fromFilter = "";
      pagingData.toFilter = "";
      pagingData.user_id = null;
      $http.get('/sms_center/logs?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page).success(function(data){
        if(data.logs.length != 0){
          $scope.showGrid = true;
          $scope.logs = data;
          $scope.pagingData.TotalItems = data.total;
          setPager();
        }else{
          $scope.showGrid = false;
        }
      });   
      // $scope.filterLogs(pagingData);
    }

    $scope.downloadLogs = function(pagingData){
      if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id == null) {
        $window.open('sms_center/downloads/logs.csv?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id != null){
        $window.open('sms_center/downloads/logs.csv?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page + '&user_id=' + pagingData.user_id);
      }else if(pagingData.toFilter !="" && pagingData.fromFilter != "" && pagingData.user_id == null){
        $window.open('sms_center/downloads/logs.csv?start_date=' + pagingData.fromFilter + '&end_date=' + pagingData.toFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        $window.open('sms_center/downloads/logs.csv?start_date=' + pagingData.fromFilter + '&end_date=' + pagingData.toFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page + '&user_id=' + pagingData.user_id);
      }
    }

    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.filterLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };
    
    //pagination ends here----------------------------------------------------
  }
]);


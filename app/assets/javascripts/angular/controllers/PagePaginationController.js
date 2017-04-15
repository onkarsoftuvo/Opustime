app.controller("PagePaginationController",[
  '$scope',
  '$rootScope',
  'pageService',
  function($scope, $rootScope, pageService){
    init();

    function init() {
      $rootScope.pager = [];
      $rootScope.pager.maxSize = 8;
      $rootScope.pager.totalItems = 0;
      $rootScope.pager.currentPage = 1;
      $rootScope.pager.pageSize = 10;
      $rootScope.pager.pageSizeValues = [10, 20, 30];
      $rootScope.pager.pagerContext = "";
      $rootScope.pager.showPager = false;
      $rootScope.pager.fromFilter = '';
      $rootScope.pager.toFilter = '';
      $rootScope.pager.user_id = null;

      $scope.onSelectPage = function (pagingData, pageno) {
        //  $rootScope.pager.currentPage = Math.ceil(page);
        pagingData.Page = pageno;
        if ($rootScope.pager.currentPage < 1 || $rootScope.pager.currentPage > Math.ceil($rootScope.pager.totalItems / $rootScope.pager.pageSize)) {
            return;
        }
        // var pagingData = $scope.readPagingData();
        setPage(pagingData);
        //Broad Cast to PageOrderController Pass Paging Data
        $rootScope.$broadcast('PagerSelectPage', pagingData);
      };

      $scope.onSelectPageSize = function (pagingData, pageSize) {
          // var pagingData = $scope.readPagingData();
          pagingData.PageSize = pageSize;
          setPage(pagingData);
          $rootScope.$broadcast('PagerSelectPage', pagingData);
      };

      $scope.readPagingData = function () {
          var pagingData = {
              "TotalItems": $rootScope.pager.totalItems,
              "Page": $rootScope.pager.currentPage,
              "PageSize": $rootScope.pager.pageSize,
              "fromFilter": $rootScope.pager.fromFilter,
              "toFilter": $rootScope.pager.toFilter,
              "user_id": $rootScope.pager.user_id
          };
          return pagingData;
      };

      // $scope.$on('PagerResetData', function (event) {
      //     $rootScope.pager.totalItems = 0;
      //     $rootScope.pager.currentPage = 0;
      //     $rootScope.pager.fromFilter = "";
      //     $rootScope.pager.toFilter = "";
      //     $rootScope.pager.showPager = false;
      // });

      // $rootScope.$on('PagerSetData', function (event, data) {
      //     if (data.Page == 1) {
      //         setPage(data);
      //     }
      // });

      // $scope.$on('PagerSetDataDelete', function (event, data) {
      //     setPage(data);
      // });

      $rootScope.initPager = function () {
        var data = pageService.getPaging();
        setPage(data);
        //BroadCast the parent controller when the Pagination control is initialized             
        var readdata = $scope.readPagingData();
        $rootScope.$broadcast('PagerInitialized', readdata);
      };

      function setPage(data) {
          $rootScope.pager.totalItems = data.TotalItems;
          $rootScope.pager.currentPage = data.Page;
          $rootScope.pager.pageSize = data.PageSize;
          $rootScope.pager.fromFilter = data.fromFilter;
          $rootScope.pager.toFilter = data.toFilter;
          $rootScope.pager.user_id = data.user_id;
          $rootScope.pager.showPager = ($rootScope.pager.totalItems > 0);
      }
    }
  }
]);
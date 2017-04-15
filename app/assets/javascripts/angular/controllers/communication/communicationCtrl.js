app.controller('communicationCtrl', [
  '$rootScope',
  '$scope',
  '$http',
  '$timeout',
  '$q',
  '$state',
  'pageService',
  function ($rootScope, $scope, $http, $timeout, $q, $state, pageService) {
    //Get Communication list-----------------------------------
    $scope.noModule = false;
    $scope.header = {
      module:'sidebar_menu.Communication',
      title:'controllerVeriable.newSms',
      back_link: 'communication',
    }

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

    // $scope.getCommunicationList = function () {
    //   $rootScope.cloading = true;
    //   $http.get('/communications').success(function (list) {
    //     if(list.communications.length != 0){
    //       for (var i = 0; i < list.communications.length; i++) {
    //         list.communications[i].isopen = false;
    //       }
    //       $scope.CommunicationList = list.communications;
    //       $scope.CommunicationDetail = list;
    //       $scope.pagingData.TotalItems = list.total;
    //       $scope.showGrid = true;
    //       setPager();
    //     }else{
    //       $scope.showGrid = false;
    //       $scope.noModule = true;
    //       $scope.noData = true;
    //     }
    //     if ($scope.CommunicationList.length == 0) {
    //       $scope.noModule = true;
    //       $scope.noData = true;
    //     }
    //     $rootScope.cloading = false;
    //   });
    // }

    $scope.communicationLogs = function(pagingData) {
      $scope.CommunicationList = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/communications?per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
      }else{
        obj = $http.get('/communications?q=' + pagingData.fromFilter + '&per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
      }
      obj.success(function(list){
        if(list.communications.length != 0){
          for (var i = 0; i < list.communications.length; i++) {
            list.communications[i].isopen = false;
          }
          $scope.CommunicationList = list.communications;
          $scope.CommunicationDetail = list;
          $scope.pagingData.TotalItems = list.total;
          $scope.noRecordFount = false;
          $scope.showGrid = true;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
      });
    }
    
    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/communications/check/security_roles').success(function(data){
          console.log(data);
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')  
          }
          else{
            $scope.communicationLogs($scope.pagingData);
          }
          resolve();
        });
      });
    }
    $scope.hitCom = getPermissions();

    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.communicationLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };
    
    //pagination ends here----------------------------------------------------

    //Clear Communication logs
    $scope.clearLogs = function(){
      $scope.pagingData.fromFilter = '';
      $scope.communicationLogs($scope.pagingData);
    }

    //filter for contact search list

    $scope.noRecordFount = false;
    var _timeout;
    // $scope.communicationSearch = function (Term) {
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     $http.get('/communications?q=' + Term).success(function (data) {
    //       $scope.CommunicationList = data.communications;
    //       $scope.CommunicationDetail = data;
    //       if ($scope.CommunicationList.length == 0) {
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
    //------------------------------------------------------------------------  
    //Get inner detail for communication

    $scope.showCommunicationDetails = function (index) {
      if ($scope.CommunicationList[index].isopen) {
        return true;
      }
    }

    $scope.opened = function (index, id) {
      $timeout(function () {
        if ($scope.CommunicationList[index].isopen) {
          $rootScope.cloading = true;
          $http.get('/communications/' + id).success(function (results) {
            $rootScope.cloading = false;
            $scope.commDetails = results;
          });
        } 
        else if (!$scope.CommunicationList[index].isopen) {
          $scope.commDetails = '';
        }
      })
    }
    //------------------------------------------------------------------------

  }
]);

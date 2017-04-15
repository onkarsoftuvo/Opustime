app.controller('contactCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$timeout',
  '$translate',
  '$q',
  'pageService',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $timeout, $translate, $q, pageService) {
    init();

    $scope.editContact = function(id){
      $state.go('contact.edit', {'con_id': id})
    }

    function init(){
      $scope.paging = {};
      $scope.paging.fromFilter = '',
      $scope.paging.toFilter = '',
      $scope.paging.Page = 1;
      $scope.paging.TotalItems = 0;
      $scope.paging.PageSize = 30;
      $scope.showGrid = false;
    }
    
    //get contact list
    // $scope.pagging = [];
    // $scope.noModule = false;
    // $scope.getContactList = function () {
    //   $rootScope.cloading = true;
    //   $http.get('/contacts').success(function (list) {
    //     for (var i = 0; i < list.length; i++) {
    //       list[i].isopen = false;
    //     }
    //     $scope.ContactList = list.contacts_list;
    //     $scope.ContactDetail = list;
    //     if ($scope.ContactList.length == 0) {
    //       $scope.noModule = true;
    //       $scope.noData = true;
    //     }
    //     else{
    //       $scope.noModule = false;
    //       $scope.noData = false;
    //     }
    //     $scope.pagging = [];
    //     for (i = 1; i <= $scope.ContactDetail.pagination.total_pages; i++) {
    //       $scope.pagging.push({
    //         'pageNo': i
    //       });
    //     }
    //     $rootScope.cloading = false;
    //   });
    // }

    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/contacts/security_roles').success(function(data){
          $rootScope.conPerm = data;
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')   
          }
          else{
            $scope.contactLogs($scope.paging);
          }
          resolve();
        });
      });
    }
    $scope.hitCon = getPermissions();

    $scope.contactLogs = function(pagingData) {
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/contacts?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = $http.get('/contacts?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.success(function(list){
        if(list.contacts_list.length != 0){
          for (var i = 0; i < list.length; i++) {
            list[i].isopen = false;
          }
          $scope.ContactList = list.contacts_list;
          $scope.ContactDetail = list;
          $scope.paging.TotalItems = list.total;
          $scope.showGrid = true;
          $scope.noRecordFount = false;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
        $rootScope.cloading = false;
      });
    }

    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.paging = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.paging = pagingData;
      $scope.contactLogs($scope.paging);
    });

    function setPager() {
      pageService.setPaging($scope.paging);
    };

    //pagination ends here----------------------------------------------------

    //Clear contact logs
    $scope.clearLogs = function() {
      $scope.paging.fromFilter = "";
      $scope.contactLogs($scope.paging); 
    }

    //filter for contact search list
    // $scope.noRecordFount = false;
    // var _timeout;
    // $scope.contaxtSearch = function (Term) {
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     console.log('Here the search item: ', Term);
    //     $http.get('/contacts?q=' + Term).success(function (data) {
    //       console.log('Here the filter results: ', data);
    //       $scope.ContactList = data.contacts_list;
    //       $scope.ContactDetail = data;
    //       if ($scope.ContactList.length == 0) {
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
 
    $scope.openConfirm = function (size, id, events) {
      $scope.con_id = id;
      $scope.con_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };

    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($scope.DeleteContact($scope.con_id, $scope.con_events));
    };

    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };

    $scope.DeleteContact = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete('/contacts/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.businessInfo = results.data;
          //$scope.getContactList();
          $rootScope.cloading = false;
          $translate('toast.contactDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }

  }
]);

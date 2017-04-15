app.controller('UserSettingCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$state',
  function($scope, $rootScope, $http, filterFilter, Data, $state) {
    $rootScope.userBtnText = '';
    $rootScope.showBlank = true;
    $rootScope.BtnSave = false;
    $rootScope.settingtopClasses1 = 'col-md-12 col-xs-12 top-links';
    $rootScope.settingtopClasses2 = 'hide';
    //get current time zone
    Data.getTimezone().then(function (results) {
      $scope.timezone = results.data;
    });

    //get user list
    $scope.getUsersList = function () {
      Data.get('/settings/users').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          results.forEach(function(user){
            if ($scope.permissionsData.logged_in_user_id == user.id && $scope.permissionsData.view_own) {
              user.isLink = true
            }
            else if($scope.permissionsData.logged_in_user_id != user.id && $scope.permissionsData.manage_others){
              user.isLink = true;
            }
            else{
              user.isLink = false;
            }
          });
          $scope.userList = results;
        }
      })
    }
    //get user list

    function getPermission(){
      $http.get('/settings/users/security_roles').success(function(data){
        $scope.permissionsData = data;
        $scope.getUsersList();
      });
    }
    getPermission()
    //getting Business List
    $rootScope.getBusinessList = function() {
      Data.get('/settings/business').then(function (results) {
        $rootScope.cloading = false;
        if (!results.code) {
          $rootScope.businessList = results;
        }
      });
    }
    $rootScope.getBusinessList();
  }
]);

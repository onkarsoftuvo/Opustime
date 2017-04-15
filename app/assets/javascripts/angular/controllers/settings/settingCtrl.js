app.controller('settingCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'Data',
  'Upload',
  'toplink',
  '$state',
  function ($scope, $location, $rootScope, $http, Data, Upload, toplink, $state) {
    //authorization top links 
    /*$scope.Authorization = function () {
      $http.get('/authorized/modules').success(function (response) {
        $rootScope.toplinks = response.result.settings;
      });
    }
    $scope.Authorization();*/
    $rootScope.selected_timeZone = '-12';
    /*if (!$rootScope.DashboardLinks.setting) {
      $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
      $state.go('dashboard');
    }*/
  }
]);
//account setting controller
app.controller('AccountsettingCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'Data',
  'Upload',
  '$translate',
  '$state',
  function ($scope, $location, $rootScope, $http, Data, Upload, $translate, $state) {
    $scope.account = [];
    
    //Update Account Setting
    $scope.settingSubmit = function (file, data) {
      document.getElementById('settingLogo').style.borderColor = '#37628f';
      if(file && file.size > 2000000){
        $rootScope.errors = [{"error_name" : "Logo", "error_msg":"is larger than 2 MB"}];
        $rootScope.showMultyErrorToast();
        document.getElementById('settingLogo').style.borderColor = "red";
        return false;
      }
      $rootScope.cloading = true;
      $http.put('/settings/account/' + data.id, data).success(function (results) {
        $rootScope.cloading = false;
        if (results.error) {
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
        } 
        else {
          if (file.blobUrl == undefined) {
            $rootScope.getAtendee();
          }
          if (file.blobUrl != undefined) {
            $rootScope.cloading = true;
            Upload.upload({
              url: '/settings/account/' + data.id + '/upload',
              method: 'PUT',
              file: file
            }).progress(function (evt) {
              var progressPercentage = parseInt(100 * evt.loaded / evt.total);
            }).success(function (data, status, headers, config) {
              if (data.error) {
                $rootScope.errors = data.error;
                $rootScope.showMultyErrorToast();
                $rootScope.cloading = false;
              } 
              else {
                $rootScope.getAtendee();
                $translate('toast.settingsUpdated').then(function (msg) {
                  $rootScope.showSimpleToast(msg);
                });
                $scope.Settingget();
                $rootScope.cloading = false;
              }
            }).error(function (data, status, headers, config) {
            })
          }
        }
      });
    }

    //Get account setting
    $scope.Settingget = function () {
      $http.get('/settings/account').success(function (response, error) {
        if (response.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.account = response;
          if(response.calendar_setting.height == 'small') {
            $scope.account.calendar_setting.height = 22;
          }
        }
      });
    }
     
    //Get Timezone
    $scope.GatAccountSettings = function () {
      Data.getTimezone().then(function (results) {
        $scope.timezone = results.data;
        Data.getCountry().then(function (results) {
          $scope.country = results;
          $scope.Settingget();
        });
      });
    }
    
    $scope.GatAccountSettings();
  }
]);

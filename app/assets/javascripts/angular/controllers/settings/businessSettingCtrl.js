app.controller('businessSettingCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  '$modal',
  'filterFilter',
  'Data',
  '$state',
  
  function ($scope, $location, $rootScope, $http, $modal, filterFilter, Data, $state) {
    $rootScope.showBlank = true;
    $rootScope.settingtopClasses1 = 'col-md-12 col-xs-6 top-links';
    $rootScope.settingtopClasses2 = 'col-md-2 col-xs-6 top-btn';
    $rootScope.hideBusinessCancel = true;
    $rootScope.showDelete = false;
    $scope.countryf = [];

    $rootScope.getBusinessList = function () {
      Data.get('/settings/business').then(function (results) {
        $rootScope.cloading = false;
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $rootScope.businessList = results;
          Data.getCountry().then(function (data) {
            $scope.countryf = data;
            for (var i = 0; i < $rootScope.businessList.length; i++) {
              $scope.Jfilename = filterFilter($scope.countryf, {
                code: $rootScope.businessList[i].country
              });
              $rootScope.businessList[i].country = $scope.Jfilename[0].name;
            };
          });
        }
        
      });
    }
    Data.getCountry().then(function (results) {
      $scope.country = results;
    });
    //get business list
    $rootScope.getBusinessList();
    //delete business 
    $rootScope.DeleteBusiness = function () {
      $http.delete ('/settings/business/' + $rootScope.business_id).success(function (results) {
        if (results.flag == true) {
          $state.go('settings.business');
          $rootScope.showBlank = true;
        }
        $rootScope.getBusinessList();
      });
    }
    //open delete business confirmation box

    $scope.openDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteBusiness());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $rootScope.showTooltip = function (data) {
    }
  }

]);
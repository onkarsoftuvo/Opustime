app.controller('businessinfoCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$translate',
  function ($scope, $rootScope, $http, filterFilter, Data, $stateParams, $state, $translate) {
    $rootScope.showBlank = false;
    $scope.businessInfo = [];
    $scope.country = '';
    $rootScope.hideBusinessCancel = false;
    $rootScope.business_id = $stateParams.business_id;
    $rootScope.mainButton = 'button.update';
    $rootScope.settingtopClasses1 = 'col-md-8 col-xs-6 top-links';
    $rootScope.settingtopClasses2 = 'col-md-4 col-xs-6 top-btn';
    $rootScope.showDelete = true;
    //get country
    Data.getCountry().then(function (results) {
      $scope.country = results;
    });
    //get states list according to country
    $scope.GetStates = function (data) {
      $scope.state = '';
      Data.getCountry().then(function (results) {
        $scope.countryf = results;
        $scope.Jfilename = filterFilter($scope.countryf, {
          code: data
        });
        Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
          $scope.state = results;
        });
      });
    };
    $rootScope.getBusinessList()
    //save bussiness list
    $scope.settingSubmit = function (data) {
      $rootScope.cloading = true;
      $http.put('/settings/business/' + $stateParams.business_id, data).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.businessInfo = results.data;
          $rootScope.getBusinessList();
          $rootScope.getAtendee();
          $rootScope.cloading = false;
          $translate('toast.businessUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }
    //get Business Detail
    $http.get('/settings/business/' + $stateParams.business_id + '/edit').success(function (results) {
      if (!results.code) {
        $scope.businessResults = results;
        if ($scope.businessResults.country) {
          //get Business country name and states
          Data.getCountry().then(function (results) {
            $scope.countryf = results;
            $scope.Jfilename = filterFilter($scope.countryf, {
              code: $scope.businessResults.country
            });
            Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
              $scope.state = results;
              setTimeout(function () {
                $scope.$apply(function () {
                  $scope.businessInfo = $scope.businessResults;
                  $rootScope.hideBusinessCancel = true;
                });
              });
            });
          });
        } 
        else {
          setTimeout(function () {
            $scope.$apply(function () {
              $scope.businessInfo = $scope.businessResults;
            });
          });
        }
      }
    });
  }
]);

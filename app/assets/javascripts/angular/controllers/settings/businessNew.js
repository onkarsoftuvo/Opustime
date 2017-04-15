app.controller('businessNew', [
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
    $rootScope.mainButton = 'button.create';
    $rootScope.hideBusinessCancel = true;
    $rootScope.settingtopClasses1 = 'col-md-9 col-xs-6 top-links';
    $rootScope.settingtopClasses2 = 'col-md-3 col-xs-6 top-btn';
    $rootScope.showDelete = false;
    $http.get('/settings/business/new').success(function (results) {
      $scope.businessInfo = results;
    });
    //save new business 
    $scope.CreateBusiness = function (data) {
      $rootScope.cloading = true;
      $http.post('/settings/business/', {
        business: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.businessInfo = results.data;
          $translate('toast.businessAdded').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $state.go('settings.business.info', {
            business_id: results.business_id
          })
          Data.get('/settings/' + $rootScope.comp_id + '/business').then(function (results) {
            $scope.businessList = results;
          });
          $rootScope.getBusinessList();
        }
      });
    }
    Data.getCountry().then(function (results) {
      $scope.country = results;
      $http.get('http://ipinfo.io/json').success(function (results) {
        $rootScope.ipDetails = results;
        $scope.businessInfo.country = $rootScope.ipDetails.country;
        $scope.Toffset = new Date().getTimezoneOffset();
        $scope.GetStates($scope.businessInfo.country);
      });
    });
    //get states
    $scope.GetStates = function (data) {
        //console.log("data", data)
      $scope.state = '';
      Data.getCountry().then(function (results) {
        $scope.countryf = results;
        $scope.Jfilename = filterFilter($scope.countryf, {
          code: data
        });
        Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
          $scope.state = results;
          $scope.businessInfo.state = $scope.state[0].code;
        });
      });
    };
  }
]);
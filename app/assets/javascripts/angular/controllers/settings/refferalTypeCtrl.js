app.controller('refferalTypeCtrl', [
  '$scope',
  '$rootScope',
  '$state',
  '$http',
  '$modal',
  function ($scope, $rootScope, $state, $http, $modal) {
    $scope.referral = {
      referral_type_subcats_attributes: []
    };
    $scope.getReferralList=function() {
      $http.get('/referral_types').success(function (list) {
        if (list.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.referralList = list;
        }
      });
    } 
    $scope.getReferralList();
    //delete refferal type
    $scope.reffDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.deleteReferral());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $scope.getreferralDetails=function () {
      if ($state.params.referalID != undefined && $state.params.referalID != 'new') {
        $rootScope.cloading = true;
        $http.get('/referral_types/' + $state.params.referalID + '/edit').success(function (details) {
          if (!details.code) {
            $scope.referral = details;
          }
          $rootScope.cloading = false;
        });
      }
    }
    if ($state.params.referalID == 'new') {
      $scope.showSave = true;
      $scope.showdelete = false;
      $scope.showCancel = true;
      $scope.hideall = false;
    } 
    else if ($state.params.referalID == undefined) {
      $scope.hideall = true;
    } 
    else if ($state.params.referalID != 'new') {
      $scope.showSave = false;
      $scope.showCancel = true;
      $scope.hideall = false;
      $scope.showdelete = true;
      $scope.getreferralDetails();
    }
    $rootScope.$on('$stateChangeStart', function (event, toState, toParams, fromState, fromParams) {
      $scope.getReferralList();
      if (toParams.referalID == 'new') {
        $scope.showSave = true;
        $scope.showdelete = false;
        $scope.showCancel = true;
        $scope.hideall = false;
        $scope.referral = {
          referral_type_subcats_attributes: [
          ]
        };
      } 
      else if (toParams.referalID == undefined) {
        $scope.hideall = true;
      } 
      else if (toParams.referalID != 'new') {
        $scope.showSave = false;
        $scope.showCancel = true;
        $scope.hideall = false;
        $scope.showdelete = true;
        $scope.getreferralDetails();
      }
    })
    //add new referral into array
    $scope.AddReferral = function () {
      $scope.referral.referral_type_subcats_attributes.push({
        sub_name: ''
      });
    }
    //remove raferral from array

    $scope.removeReferral = function (index) {
      $scope.referral.referral_type_subcats_attributes.splice(index, 1);
    }
  }
]);
app.controller('refferalTypeFormCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$state',
  '$translate',
  function ($scope, $rootScope, $http, $state, $translate) {
    if ($state.params.referalID != 'new') {
      $http.get('/referral_types/' + $state.params.referalID + '/edit').success(function (details) {
        if (details.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.referral = details;
        }
        $rootScope.cloading = false;
      });
    }
    $rootScope.$on('$stateChangeStart', function (event, toState, toParams, fromState, fromParams) {
      $scope.getReferralList();
      if (toParams.referalID == 'new') {
        $scope.showSave = true;
        $scope.showdelete = false;
        $scope.showCancel = true;
        $scope.hideall = false;
      } 
      else if (toParams.referalID == undefined) {
        $scope.hideall = true;
      } 
      else if (toParams.referalID != 'new') {
        $scope.showSave = false;
        $scope.showCancel = true;
        $scope.hideall = false;
        $scope.showdelete = true;
        $scope.getreferralDetails();
      }
    })
    $scope.AddReferral = function () {
      $scope.referral.referral_type_subcats_attributes.push({
        sub_name: ''
      })
    }
    $scope.removeReferral = function (index) {
      $scope.referral.referral_type_subcats_attributes.splice(index, 1);
    }
    $rootScope.deleteReferral = function () {
      $rootScope.cloading = true;
      $http.delete ('/referral_types/' + $state.params.referalID).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $state.go('settings.referral-types');
          $scope.getReferralList();
          $translate('toast.referralTypeDeleted').then(function (msg) {
	        $rootScope.showSimpleToast(msg);
	      });
        }
      });
    }
    $scope.referralSubmit = function (data) {
      $rootScope.cloading = true;
      if (data.id) {
        $http.put('/referral_types/' + data.id, {
          referral_type: data
        }).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $scope.getreferralDetails();
            $scope.getReferralList();
            $rootScope.cloading = false;
            $translate('toast.referralTypeUpdated').then(function (msg) {
		      $rootScope.showSimpleToast(msg);
		    });
          }
        })
      } 
      else {
        $http.post('/referral_types', {
          referral_type: data
        }).success(function (results) {
          console.log(results);
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $rootScope.cloading = false;
            $state.go('settings.referral-types.edit', {
              referalID: results.id
            })
            $scope.getReferralList();
            $translate('toast.referralTypeCreated').then(function (msg) {
		      $rootScope.showSimpleToast(msg);
		    });
          }
        })
      }
    }
  }
]);

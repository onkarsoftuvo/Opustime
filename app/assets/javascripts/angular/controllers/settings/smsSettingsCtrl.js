app.controller('smsSettingCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$modal',
  '$translate',
  '$state',
  function ($scope, $rootScope, $http, Data, $modal, $translate, $state) {
    //edit sms settings
    $scope.getSmsSettings = function () {
      Data.get('/settings/sms_setting/edit').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.smsSettings = results.sms_setting_detail;
          $scope.smsSettings.sms_alert_no = ($scope.smsSettings.sms_alert_no).toString();
          $scope.smsPlans = results.sms_plans;
          $scope.smssettings.sms_alert_no = '' + $scope.smssettings.sms_alert_no;
          $rootScope.smsCount = results.sms_setting_detail.default_sms;
        }
      });
    }
    $scope.getSmsSettings();
    //Update SMS 
    $scope.SMSSubmit = function (data) {
      $rootScope.cloading = true;
      $http.put('/settings/sms_setting', {
        'sms_setting': data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $scope.getSmsSettings();
          $translate('toast.smsSettingsUpdated').then(function (msg) {
	        $rootScope.showSimpleToast(msg);
	      });
          $rootScope.cloading = false;
        }
      });
    }
    $scope.smssettings = {
      sms_alert_no: 100
    }
    //open delete confirmation popup
    $scope.openConfirm = function (data) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'smsConfirm.html',
        controller: 'SMSUpdate',
        size: 'sm',
        resolve: {
          plan: function () {
            return data;
          }
        }
      });
    };
  }
]);
app.controller('SMSUpdate', [
  '$scope',
  '$modalInstance',
  'plan',
  '$rootScope',
  '$translate',
  '$http',
  function ($scope, $modalInstance, plan, $rootScope, $translate, $http) {
    $scope.plan = plan;
    console.log($scope.plan)
    //update SMS plans
    $scope.UpdateSMSPlan = function (id) {
      /*$http.put('').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.businessDataUpdated').then(function (msg) {
  	      $rootScope.showSimpleToast(msg);
  	    });
      });*/
      $rootScope.cloading = true;
      var data = {'id' : $rootScope.User_id, 'plan_id' : id};
      console.log(data);
      $http.get('/settings/authorizenet/sms_credit_payment?id=' + $rootScope.User_id + '&plan_id=' + id).success(function(result){
        console.log(result);
        $rootScope.cloading = false;
        if (result.flag) {
          $rootScope.showSimpleToast(result.message);
          $rootScope.smsCount = result.data.sms_count;
        }
        else{
          $rootScope.errors = [
            {
              'error_msg' : result.message
            }
          ];
          $rootScope.showMultyErrorToast();
        }
      });
    }
    $scope.hitSmsUPdate = function (id) {
      $modalInstance.close($scope.UpdateSMSPlan(id));
    };
    $rootScope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
  }
]);

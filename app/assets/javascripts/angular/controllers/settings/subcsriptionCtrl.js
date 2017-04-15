app.controller('subcsriptionCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$translate',
  function ($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $modal, $translate) {
    $scope.planCat = 'Monthly';
    $scope.cplane = '';
    //get subscription data
    $rootScope.getSubscriptionsList = function () {
      Data.get('/settings/subscription?comp_id=' + $rootScope.User_id).then(function (results) {
        console.log(results);
        $rootScope.is_trial1 = results.is_trial;
        $rootScope.is_subscription = results.is_subscribed;
        if($rootScope.is_trial1 == false && $rootScope.is_subscription == true || $rootScope.is_trial1 == true && $rootScope.is_subscription == false){
          $rootScope.subscription_status = true;
          $rootScope.subscript = false;
          $rootScope.dashboardStatus=false;
          $rootScope.dashSubscript_status = true;
        }
       else if($rootScope.is_trial1 == false && $rootScope.is_subscription == false){
          $rootScope.subscription_status = false;
          $rootScope.subscript = true;
          $rootScope.dashboardStatus = true;
          $rootScope.dashSubscript_status = false; 
          
        }
        else {
          console.log("not done");
        }
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.subscriptionList = results.plans;
          $scope.subscriptDetails = results.subscription_detail;
          $scope.cplane = results.subscription_detail;
          $scope.subDetail = results;
        }
        
      })
    }
    $rootScope.getSubscriptionsList();
    //Update Subscription
    $rootScope.SelectPlane = function (data) {
      $rootScope.cloading = true;
      $http.put('/settings/subscription', {
        'id': data,
        'comp_id': $rootScope.User_id
      }).success(function (results) {
        if (results.flag) {
          $translate('controllerVeriable.subscriptionUpdate').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $scope.getSubscriptionsList();
        } 
        else {
          console.log(results)
          $rootScope.showErrorToast(results.message)
        }
        $rootScope.cloading = false;
      });
    } //open delete confirmation popup

    $scope.openConfirm = function (id, price) {
      var data = {
        'id': id,
        'price': price
      };
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'subConfirm.html',
        controller: 'subConfirmation',
        size: 'sm',
        resolve: {
          plan: function () {
            return data;
          }
        }
      });
    };
    //open card update popup
    $scope.openCardUpdate = function (size) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'CardUpdate.html',
        controller: 'CardUpdate',
        size: 'sm',
        resolve: {
          cplane: function () {
            return $scope.cplane;
          }
        }
      });
      $scope.modalInstance.result.then(function (color) {
        $scope.AppointmentData.appointment_type.color_code = color.color;
      });
    };
    //open cancel card popup
    $scope.cancelCardUpdate = function (size) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'cancelUpdate.html',
        controller: 'cancelUpdate',
        size: 'lg',
        resolve: {
          cplane: function () {
            return $scope.cplane;
          }
        }
      });
    };
    //check card status
    $rootScope.cardStatus = function () {
      $rootScope.cloading = true;
      $http.get('/settings/authorizenet/card_registration_status?id=' + $rootScope.User_id).success(function (data) {
        console.log(data);
        if (!data.code) {
          $rootScope.cardData = data;
        }
        $rootScope.cloading = false;
      })
    }
    $rootScope.cardStatus();
  }
]);
app.controller('CardUpdate', [
  '$scope',
  '$modalInstance',
  'cplane',
  '$rootScope',
  '$http',
  function ($scope, $modalInstance, cplane, $rootScope, $http) {
    $scope.cardDetails = {
    };
    //$scope.cardDetails.year = 'Year';
    //$scope.cardDetails.month = 'Month';
    var date = new Date();
    var curYear = date.getFullYear().toString().substr(2, 2);
    var makeSmall = curYear.split();
    $scope.currentYear = parseInt(curYear);
    $scope.addfiftyYear = $scope.currentYear + 50;
    $scope.cplane = cplane;
    $scope.buttonTxt = 'settings.zulu_subscription.update_card';
    if ($rootScope.cardData.data.company_payment_profile_id == null) {
      $scope.buttonTxt = 'SAVE CREDIT CARD';
    }
    $scope.selectColor = function () {
      $modalInstance.close($scope.selected.item);
    };
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
    $scope.UpdateCard = function (data) {
      data = angular.copy(data);
      var cardMonth = parseInt(data.expiry_month);
      if (cardMonth <= 9) {
        cardMonth = '0' + cardMonth;
      } 
      else {
        cardMonth = cardMonth;
      }
      data.expiry_month = cardMonth;
      data.id = $rootScope.User_id;
      if ($rootScope.cardData.data.company_payment_profile_id == null) {
        $http.post('/settings/authorizenet/card_registration', data).success(function (result) {
          if (result.flag) {
            $modalInstance.dismiss('cancel');
            $rootScope.showSimpleToast(result.message);
            $rootScope.cardStatus();
          } 
          else {
            if (result.is_credit_card_errors) {
              if(result.error.length > 1){
                $rootScope.errors = result.error;
                $rootScope.showMultyErrorToast();
              }else{
                $rootScope.showErrorToast(result.error[0].error_name + ' ' + result.error[0].error_msg);
              }
            } 
            else {
              if(result.error){
                if(result.error.length > 1){
                $rootScope.errors = [
                {
                  'error_msg': result.message
                }
                ];
                $rootScope.showMultyErrorToast();
                }else{
                  $rootScope.showErrorToast(result.error[0].error_msg);
                }
              }else{
                $rootScope.showErrorToast(result.message);
              }
            }
          }
        });
      } 
      else {
        $http.put('/settings/authorizenet/card_updation', data).success(function (result) {
          if(result.flag) {
            $modalInstance.dismiss('cancel');
            $rootScope.showSimpleToast(result.message);
            $rootScope.cardStatus();
          } 
          else {
            if (result.is_credit_card_errors) {
              if(result.error.length > 1){
                $rootScope.errors = result.error;
                $rootScope.showMultyErrorToast();
              }else{
                $rootScope.showErrorToast(result.error[0].error_name + ' ' + result.error[0].error_msg);
              }
            } 
            else {
              if(result.error){
                if(result.error.length > 1){
                $rootScope.errors = [
                {
                  'error_msg': result.message
                }
                ];
                $rootScope.showMultyErrorToast();
                }else{
                  $rootScope.showErrorToast(result.error[0].error_msg);
                }
              }else{
                $rootScope.showErrorToast(result.message);
              }
            }
          }
        });
      }
    }
  }
]);
app.controller('cancelUpdate', [
  '$scope',
  '$rootScope',
  '$modalInstance',
  'cplane',
  '$http',
  function ($scope, $rootScope, $modalInstance, cplane, $http) {
    $scope.cplane = cplane
    $scope.cancelsubs = {
    };
    $scope.resons = [
      {
        text: 'settings.zulu_subscription.cancelReason1'
      },
      {
        text: 'settings.zulu_subscription.cancelReason2'
      },
      {
        text: 'settings.zulu_subscription.cancelReason3'
      },
      {
        text: 'settings.zulu_subscription.cancelReason4'
      },
      {
        text: 'settings.zulu_subscription.cancelReason5'
      },
      {
        text: 'settings.zulu_subscription.cancelReason6'
      }
    ]
    $scope.selectColor = function () {
      $modalInstance.close($scope.selected.item);
    };
    $rootScope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
    $scope.CancelSubscription = function (data) {
      console.log(data);
      data.comp_id = $rootScope.User_id;
      $rootScope.cloading = true;
      $http.post('/settings/subscription/cancel', data).success(function (result) {
        console.log(result);
        if (result.flag) {
          $modalInstance.close();
          $rootScope.showSimpleToast(result.message);
          $rootScope.getSubscriptionsList();
        } 
        else {
          $modalInstance.close();
          $rootScope.errors = [
            {
              'error_msg': result.message
            }
          ];
          $rootScope.showMultyErrorToast();
        }
        $rootScope.cloading = false;
      });
    };
  }
]);
app.controller('subConfirmation', [
  '$scope',
  '$modalInstance',
  'plan',
  '$rootScope',
  '$http',
  function ($scope, $modalInstance, plan, $rootScope, $http) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
    $scope.confirmSub = function () {
      $modalInstance.dismiss('cancel');
      $rootScope.SelectPlane(plan.id);
    }
    $scope.plan = plan;
  }
]);

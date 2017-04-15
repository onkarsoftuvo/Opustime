app.controller('recallTypesCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$state',
  '$modal',
  '$translate',
  '$window',
  function ($scope, $rootScope, $http, Data, $state, $modal, $translate, $window) {
    $scope.BtnRecalltype = false;
    $scope.recalData = {
      name: '',
      period_val: '1',
      period_name: 'days'
    };
    $rootScope.BtnRecalltype = false;


    if ($state.params.recallID == 'new') {
      $rootScope.btnText = 'button.save';
      $rootScope.recallDeleteBtn = true;
      $rootScope.BtnRecalltype = true;
    }
    else if ($state.params.recallID != 'new') {
      $rootScope.btnText = 'button.update';
      $rootScope.recallDeleteBtn = false;
      $rootScope.BtnRecalltype = true;
    }


    /*Functions*/
    //Get RecallList
    function getRecallList() {
      $rootScope.cloading = true;
      Data.get('/settings/recall_types').then(function (list) {
        if (list.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $rootScope.RecallList = list;
        }
        $rootScope.cloading = false;
      });
    }
    // Get Recall Data
    function getRecallData() {
      $rootScope.cloading = true;
      if ($state.params.recallID == 'new') {
        $scope.recalData = {
          name: '',
          period_val: '1',
          period_name: 'Day(s)'
        };
      } 
      else if ($state.params.recallID != 'new' && $state.params.recallID != undefined) {
        Data.get('/settings/recall_types/' + $state.params.recallID + '/edit').then(function (data) {
          if (!data.code) {
            if (data.error) {
              $state.go('settings.recall-types.info', {
                recallID: 'new'
              });
              $rootScope.showSimpleToast(data.error);
            }
            $scope.recalData = data;
          }
          $rootScope.cloading = false;
        });
      }
    }
    getRecallData();
    getRecallList();
    // Create/Edit Recall
    $scope.RecallSubmit = function (data) {
      $rootScope.cloading = true;
      if ($state.params.recallID == 'new') {
        $http.post('/settings/recall_types', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            if($rootScope.recallPermissions.modify){
              $state.go('settings.recall-types.info', {
                recallID: results.id
              });
              $translate('toast.recallTypeCreated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            getRecallList();
            $rootScope.cloading = false;
            }else{
              $state.go('settings.recall-types', {}, { reload: true });
            }
          }
        });
      } 
      else if ($state.params.recallID != 'new') {
        $http.put('/settings/recall_types/' + $state.params.recallID, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.recallTypeUpdated').then(function (msg) {
	          $rootScope.showSimpleToast(msg);
	        });
            getRecallList();
            $rootScope.cloading = false;
          }
        });
      }
    }
    //Delete Recall
    $rootScope.DeleteRecall = function (data) {
      $rootScope.cloading = true;
      $http.delete ('/settings/recall_types/' + $state.params.recallID).success(function (results) {
        $state.go('settings.recall-types');
        $translate('toast.recallTypeDeleted').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        getRecallList();
        $rootScope.cloading = false;
      });
    }
    $scope.reDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteRecall());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };

    function checkPermission(){
      $http.get('/settings/recall_types/security_roles').success(function(data){
        $rootScope.recallPermissions = data;
      });
    }
    checkPermission();

  }
]);
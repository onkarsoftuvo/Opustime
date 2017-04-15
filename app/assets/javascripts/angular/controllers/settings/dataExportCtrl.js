app.controller('dataExportCtrl', [
  '$scope',
  '$modal',
  '$http',
  '$rootScope',
  '$translate',
  '$state',
  function ($scope, $modal, $http, $rootScope, $translate, $state) {
    //predefined elements
    $scope.noData = false;
    $scope.exData = {};
    $scope.export = {};
    $scope.exData.obj_type = '';
    var date = new Date();
    var lastDate = new Date(date.getFullYear(), date.getMonth(), 0);
    var firstDate = new Date(date.getFullYear(), date.getMonth()-3, 1);

    //Datepicker functions
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    $scope.exData.from = firstDate;
    $scope.exData.to = lastDate;

    //get treatmentnote list
    function getTreatmentNote(){
      $http.get('/settings/exports/tr_notes').success(function(data){
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.allNotes = data;
        }
      })
    }
    getTreatmentNote();

    //post export data
    $scope.exportData = function (data) {
      var start = data.from.getDate() + '/' + (data.from.getMonth()+1) + '/' + data.from.getFullYear();
      var to = data.to.getDate() + '/' + (data.to.getMonth()+1) + '/' + data.to.getFullYear();
      $scope.export.obj_type = data.obj_type;
      $scope.export.st_date = start;
      $scope.export.end_date = to;
      $scope.export = {export : $scope.export};
      $rootScope.cloading = true;
      $http.post('/settings/exports', $scope.export).success(function (results) {
      	if(results.flag){
          $translate('controllerVeriable.fileExported').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
      		$rootScope.getExportList();
      	}
	    $rootScope.cloading = false;
	  });
    };

    //get exports list
    $rootScope.getExportList = function() {
      $rootScope.cloading = true;
      $http.get('/settings/exports/lists').success(function (data) {
        $rootScope.cloading = false;
        if (!data.code) {
          $scope.exportList = data.export_listing;
          if ($scope.exportList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;  
          }
        }
	  });
    };
    $rootScope.getExportList();

    //getPermissions
    $scope.getPermissions = function(type){
      var obj = '?obj_type=' + type;
      $http.get('/settings/exports/check_access_permission_export' + obj).success(function(data){
        $scope.permissions = data;
      });
    }

    //download export data
    $scope.export_download = function (id) {
      var win = window.open('/settings/exports/'+id+'/download' , '_blank');
    };

    //delete export confirmation modal
    $scope.deleteExport = function (data) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteExport.html',
        controller: 'DeleteExportCtrl',
        size: 'sm',
        resolve: {
          data: function () {
            return data;
          }
        }
      });
    };
  }
]);
//delete modal controller
app.controller('DeleteExportCtrl', [
  '$scope',
  '$modal',
  '$modalInstance',
  'data',
  '$http',
  '$rootScope',
  '$translate',
  function ($scope, $modal, $modalInstance, data, $http, $rootScope, $translate) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }

    //Delete export
    $scope.deleteExportData = function () {
      $http.delete('/settings/exports/' + data).success(function (results) {
      	$modalInstance.dismiss('cancel');
      	if (results.flag) {
          $translate('controllerVeriable.fileDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
      	  $rootScope.getExportList();
      	}
	  });
    }
  }
]);

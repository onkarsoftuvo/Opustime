app.controller('permissionMatrixCtrl', [
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
    init();

    function init(){

    };

    $scope.getPermissionMatrix = function(){
      $http.get('/settings/permission_matrix').success(function(results){
        $scope.permissionMatrix = results;
      });
    };
    $scope.getPermissionMatrix();
  }

]);

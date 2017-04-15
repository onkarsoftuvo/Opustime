app.controller('enateimportCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  '$modal',
  function ($scope, $rootScope, $http, Data, $modal) {

    //get user list
    $scope.getUsersList = function () {
      Data.get('/settings/users').then(function (results) {
        $scope.userList = results;
      })
    }
    //get user list

    $scope.getUsersList();
    //getting Business List
    $scope.getBusinessList = function() {
      Data.get('/settings/business').then(function (results) {
        $scope.businessList = results;
      });
    }
    $scope.getBusinessList();

    $scope.importEnateData = function(){
      if($scope.selectedBusiness == undefined || $scope.selectedUser == undefined || $scope.selectedType == undefined){
        alert('please select Business,User and Import type.');
      }else{
        switch($scope.selectedType){
          case 'patients':
            $scope.importPatients();
            break;
          case 'invoices':
            $scope.importInvoices();
            break;
          case 'items':
            $scope.importBillableItems();
            break;
          default:
            break;
        }
      }
    }

    // Import patient Data
    $scope.importPatients = function(){
      $('#patients_prog').show();
      Data.get("/enateimport?type=patients&business="+$scope.selectedBusiness+"&user="+$scope.selectedUser).then(function (response) {
        if (response.flag) {
          alert('Data Import Compelete');
          $('#patients_prog').hide();
        }else{
          alert("Error : "+response.error);
        }
      });
    }

    // Import Products Data
    $scope.importBillableItems = function(){
      $('#item_prog').show();
      Data.get("/enateimport?type=items&business="+$scope.selectedBusiness+"&user="+$scope.selectedUser).then(function (response) {
        if (response.flag) {
          alert('Data Import Compelete');
          $('#item_prog').hide();
        }else{
          alert("Error : "+response.error);
        }
      });
    }

    // Import Invoices Data
    $scope.importInvoices = function(){
      $('#inv_prog').show();
      Data.get("/enateimport?type=invoices&business="+$scope.selectedBusiness+"&user="+$scope.selectedUser).then(function (response) {
        if (response.flag) {
          alert('Data Import Compelete');
          $('#inv_prog').hide();
        }else{
          alert("Error : "+response.error);
          // $scope.deleteImport();
        }
      });
    }

    // Import Relations Data
    $scope.importRelations = function(){
      $('#rel_prog').show();
      Data.get("/enateimport?type=relations&business="+$scope.selectedBusiness+"&user="+$scope.selectedUser).then(function (response) {
        if (response.flag) {
          alert('Data Import Compelete');
          $('#rel_prog').hide();
        }else{
          alert("Error : "+response.error);
          // $scope.deleteImport();
        }
      });
    }

    // Delete imported Data
    $scope.deleteImport = function(){
      Data.get("/deleteimport").then(function (response) {
        if (response.flag) {
          alert('Deleted Imported data successfully');
        }
      });
    }

    // $scope.enateimport();
  }

]);

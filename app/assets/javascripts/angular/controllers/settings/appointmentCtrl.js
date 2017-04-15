app.controller('appointmentCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$modal',
  'Data',
  '$state',
  '$stateParams',
  '$filter',
  '$translate',
  function ($scope, $rootScope, $http, $modal, Data, $state, $stateParams, $filter, $translate) {
    $rootScope.cloading = false;
    $scope.btnappointment = false;
    $scope.appointment = [];
    $rootScope.btnText = 'button.update';
    $rootScope.appDeleteBtn = false;
    $rootScope.btnappointment = false;
    //delete appointment
    $scope.appDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteAppointment());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    //hit if trying to enter a new appoitment
    if ($state.params.appointmentID == 'new') {
      $rootScope.btnText = 'button.save';
      $rootScope.appDeleteBtn = true;
      $rootScope.btnappointment = true;
    } 
    else if ($stateParams.appointmentID != 'new') {
      $rootScope.btnappointment = true;
      $rootScope.btnText = 'button.update';
      // $rootScope.appDeleteBtn = false;
    }
    /*Functions*/
    $scope.searchText = null;
    $scope.searchTextp = null;
    function getBilable() {
      Data.get('/settings/appointment_type/billable_items').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.BilableItemsList = results;
        }
      });
    }
    //get products list

     function getProductList() {
      $http.get('/settings/appointment_type/products').success(function (list) {
        if (!list.code) {
          for (var i = 0; i < list.length; i++) {
            list[i].isopen = false;
          }
          $scope.ProductsList = list;
        }
      });
    }
    //get templates

    function getTemplateNotes() {
      Data.get('/settings/template_notes').then(function (results) {
        if (!results.code) {
          $scope.TemplateNotes = results;
          $scope.TemplateNotes.unshift({
            name: 'N/A',
            id: null
          });
        }
      });
    }
    //get appointment list
    function getAppointmentsList() {
      Data.get('/settings/appointment_type').then(function (list) {
        if (!list.code) {
          $rootScope.AppointmentList = list;
        }
        $rootScope.cloading = false;
      });
    }
    //Get bilable Item
  $scope.selectedItemChnge= function(data1){
      if(data1.length!=1){
        for(i=0;i<data1.length-1;i++){
          if(data1[i].billable_item_id == data1[data1.length - 1].billable_item_id){
            data1.splice(data1.length - 1, 1);
          }
         }
    }
}
$scope.selectedproductChnge =function(productselected){
  if(productselected.length!=1){
    console.log(productselected);
        for(i=0;i<productselected.length-1;i++){
          if(productselected[i].product_id == productselected[productselected.length - 1].product_id){
            productselected.splice(productselected.length - 1, 1);
          }
         
       }
    }
}
    $scope.BilableItemsListF = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.BilableItemsList, query);
    }
    
    // Product list filter
    $scope.ProductsListf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.ProductsList, query);

    }
    // Get appointment Data
    function getAppointmentData() {
      if ($stateParams.appointmentID == 'new') {
        Data.get('/settings/appointment_type/new').then(function (data) {
          if (!data.code) {
            $scope.AppointmentData = data;
            $scope.AppointmentData.appointment_type.default_note_template = null
          }
          $rootScope.cloading = false;
        });
      } 
      else if ($stateParams.appointmentID != 'new' && $stateParams.appointmentID != undefined) {
        Data.get('/settings/appointment_type/' + $stateParams.appointmentID + '/edit').then(function (data) {
          if (!data.cde) {
            if (data.error) {
              $state.go('settings.appointment.info', {
                appointmentID: 'new'
              });
              $rootScope.showSimpleToast(data.error);
            }
            $scope.AppointmentData = data;
          }
          $rootScope.cloading = false;
        });
      }
    }
    getProductList();
    getAppointmentsList();
    getAppointmentData();
    getBilable();
    getTemplateNotes();


    $scope.test = function(data){
      console.log(data);
    }  
    $scope.$watch('$scope.AppointmentData.appointment_type.related_product', function(){
      console.log('hi')
    });
    //add new appointment
    $scope.SubmitAppointment = function (data, item) {
      $rootScope.cloading = true;
      if ($stateParams.appointmentID == 'new') {
        $http.post('/settings/appointment_type', data).success(function (results) {
          if (!results.code) {
            if (results.error) {
              $rootScope.cloading = false;
              $rootScope.errors = results.error;
              $rootScope.showMultyErrorToast();
            } 
            else {
              $state.go('settings.appointment.info', {
                appointmentID: results.id
              });
              $translate('toast.appTypeCreated').then(function (msg) {
                $rootScope.showSimpleToast(msg);
              });
              getAppointmentsList();
              $rootScope.cloading = false;
            }
          }
        });
      } 
      else if ($stateParams.appointmentID != 'new') {
        $http.put('/settings/appointment_type/' + $stateParams.appointmentID, data).success(function (results) {
          if (!results.code) {
            if (results.error) {
              $rootScope.cloading = false;
              $rootScope.errors = results.error;
              $rootScope.showMultyErrorToast();
            } 
            else {
              $translate('toast.appTypeUpdated').then(function (msg) {
                $rootScope.showSimpleToast(msg);
              });
              getAppointmentsList();
              $rootScope.cloading = false;
              getAppointmentData();
            }
          }
        });
      }
    }
    //delete appointment

    $rootScope.DeleteAppointment = function (data) {
      $rootScope.cloading = true;
      $http.delete ('/settings/appointment_type/' + $stateParams.appointmentID).success(function (results) {
        $state.go('settings.appointment');
        $translate('toast.appTypeDeleted').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        getAppointmentsList();
        $rootScope.cloading = false;
      });
    }
    /*Initialization*/
    var colors = [
      {
        color: '#ff8da8'
      },
      {
        color: '#99f8ff'
      },
      {
        color: '#a2d7ff'
      },
      {
        color: '#dea8ff'
      },
      {
        color: '#00e9a8'
      },
      {
        color: '#e91849'
      },
      {
        color: '#16ddec'
      },
      {
        color: '#108fee'
      },
      {
        color: '#9813ea'
      },
      {
        color: '#00ca65'
      },
      {
        color: '#b93e5b'
      },
      {
        color: '#3db8c1'
      },
      {
        color: '#266da2'
      },
      {
        color: '#8457a0'
      },
      {
        color: '#009919'
      },
      {
        color: '#930339'
      },
      {
        color: '#25777f'
      },
      {
        color: '#113d5f'
      },
      {
        color: '#6d2c67'
      },
      {
        color: '#004d00'
      }
    ];
    $scope.items = colors;
    //color popup
    $scope.openColors = function (size) {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'selectColor.html',
        controller: 'selectClr',
        size: 'sm',
        resolve: {
          items: function () {
            return $scope.items;
          }
        }
      });
      $scope.modalInstance.result.then(function (color) {
        $scope.AppointmentData.appointment_type.color_code = color.color;
      });
    };
  }
]);
app.controller('selectClr', [
  '$scope',
  '$modalInstance',
  'items',
  function ($scope, $modalInstance, items) {
    $scope.items = items;
    $scope.selected = {
      item: $scope.items[0]
    };
    //select color
    $scope.selectColor = function () {
      $modalInstance.close($scope.selected.item);
    };
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
  }
]);

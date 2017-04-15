app.controller('add_edit_contactCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$timeout',
  '$translate',
  '$stateParams',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $timeout, $translate, $stateParams) {
    $scope.hv_next_pre = false;
    $scope.editCon = false;
    $scope.Contact = {};
    //$scope.Contact.title = 'dr';
    $scope.Contact.contact_type = 'Standard',
    $scope.Contact.phone_list = [
      {
        contact_no: '',
        type: 'mobile'
      }
    ];
    $scope.header = {
      module:'controllerVeriable.contact',
      title:'controllerVeriable.newContact',
      back_link: 'contact',
    }

    //add new phone into array
    $scope.addPhone = function () {
      $scope.Contact.phone_list.push({
        contact_no: '',
        type: 'mobile'
      });
    }

    //remove current phone from array
    $scope.removePhone = function (index) {
      $scope.Contact.phone_list.splice(index, 1);
    }

    //create new contact
    $scope.CreateContact = function (data) {
      $rootScope.cloading = true;
      if ($stateParams.con_id) {
        $scope.UpdateContact(data);
      }
      else{
        $http.post('/contacts', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            // $state.go('contact');
            // $scope.$parent.getContactList();
            $state.go('contact',{}, { reload: true});
            $rootScope.cloading = false;
            $translate('toast.contactAdded').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
        });
      }
    }
    //get contact list
    $scope.editContact = function (id) {
      $rootScope.cloading = true;
      $http.get('/contacts/' + id + '/edit').success(function (results) {
        $scope.Contact = results;
        var s_country = results.country;
        if (results.country) {
          $scope.Jfilename = filterFilter($scope.country, {
            code: results.country
          });
          if ($scope.Jfilename.length) {
            Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (list) {
              $scope.state = list;
              $scope.ContactDetails = results;
              $scope.ContactDetails.country = s_country;
              $scope.Contact = results;
              $scope.Contact.country = s_country;
              $rootScope.cloading = false;
            });
          } 
          else {
            $scope.ContactDetails = results;
			$scope.ContactDetails.country = s_country;
            $rootScope.cloading = false;
          }
        } 
        else {
          $scope.ContactDetails = results;
          $rootScope.cloading = false;
        }
      });
      $scope.contactDetails = true;
      $scope.edit_contact = false;
    }

   
 
    $scope.businessInfo = [];
    $scope.cntry = '';
    $scope.country = '';
    Data.getCountry().then(function (results) {
      $scope.country = results;
      $http.get('http://ipinfo.io/json').success(function (results) {
        $rootScope.ipDetails = results;
		if($scope.Contact.country == null || $scope.Contact.country == undefined){
			$scope.Contact.country = $rootScope.ipDetails.country;
		}
        $scope.Toffset = new Date().getTimezoneOffset();
        if (!$stateParams.con_id) {
          $scope.GetStates($scope.Contact.country);
        }
        
      });
    });
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

    if($stateParams.con_id){
      $scope.header.title = 'controllerVeriable.editContact';
      $scope.editCon = true;
      $scope.hv_next_pre = true;
      $scope.GetStates($scope.Contact.country);
      $timeout(function() {
        $scope.editContact($stateParams.con_id)
      }, 500);
    }

    $scope.createEdit = true;
    $scope.hitCon.then(function(greeting){
      if(!$stateParams.con_id){
        if(!$rootScope.conPerm.create){
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
      }
      else{
        if (!$rootScope.conPerm.modify) {
          $scope.createEdit = false;
        }
      }
    });

    $scope.UpdateContact = function (data) {
      $rootScope.cloading = true;
      $http.put('/contacts/' + data.id, {
        contact: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $state.go('contact')
          $translate('toast.contactUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
        }
      })
    }
    //hit cancel
    $scope.hitCancel = function(){
      $state.go('contact');
    }
  }
]);

app.controller('addEditPatientController', [
  '$rootScope',
  '$scope',
  'Data',
  '$http',
  'filterFilter',
  '$modal',
  '$filter',
  '$timeout',
  '$translate',
  '$state',
  '$stateParams',
    'Upload',
  function ($rootScope, $scope, Data, $http, filterFilter, $modal, $filter, $timeout, $translate, $state, $stateParams, Upload) {
    $scope.new_pati = false;
    $scope.AddPatient = true;
    $scope.maxDate = new Date();
    $scope.searchPatienttext = '';
    $scope.header = {
      module:'controllerVeriable.patient',
      title:'controllerVeriable.newPatient',
      back_link: 'patient',
    }
    function isNew(){
      $http.get('/patients/new').success(function(data){
        if (!data.status) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
      })
    }
    isNew();

    $translate('controllerVeriable.patient', $rootScope.translationData).then(function(msg) {
      $scope.header.module = msg;
    });

    $translate('controllerVeriable.newPatient', $rootScope.translationData).then(function(msg) {
      $scope.header.title = msg;
    });
    
    $scope.editPatient = false;

    $scope.Patient = {
      relationship: [],
      gender: 'Male',
      patient_contacts_attributes: [
        {
          contact_no: '',
          contact_type: 'mobile'
        }
      ]
    };

    $scope.addRelative = function () {
      $scope.Patient.relationship.push({
        patient: '',
        type: 'Parent'
      })
    }

    //get user role and authontications
    $scope.userRole = function () {
      $http.get('/patients/get/authority').success(function (data) {
        $rootScope.roleData = data;
      });
    }
    $scope.userRole();

    $scope.removeRelative = function (index) {
      $scope.Patient.relationship.splice(index, 1)
    }

    $scope.addPhone = function () {
      $scope.Patient.patient_contacts_attributes.push({
        contact_no: '',
        contact_type: 'mobile'
      })
    }

    $scope.removePhone = function (index) {
      $scope.Patient.patient_contacts_attributes.splice(index, 1)
    }
    
    //get concession list
    $scope.getConcessionList = function () {
      $http.get('/settings/concession_type').success(function (results) {
        $scope.ConcessionTypeList = results;
      })
    }
    $scope.getConcessionList();

    //get Reffral Type
    $scope.getReferralType = function () {
      $http.get('/referrals').success(function (results) {
        $scope.ReferralTypeList = results;
      })
    }
    $scope.getReferralType();

    //get patient consession type
    $scope.Patient.concession_type = 'none';
    $scope.getDoctorList = function () {
      $http.get('/patients/doctors').success(function (list) {
        $scope.DoctorList = list;
      });
    }
    $scope.getDoctorList();
    
    //get related patients
    $scope.getRelatedPatient = function () {
      $http.get('/patients/related_patients').success(function (list) {
        $scope.PatientListRefine = list;
      });
    }

    //get refine patients
    $scope.PatientListRefinef = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.PatientListRefine, query)
    }

    //get contacts
    $scope.Contact = function () {
      $http.get('/patients/contacts').success(function (list) {
        $scope.contactsLists = list;
      });
    }
    $scope.Contact();

    $scope.Contactf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.contactsLists, query)
    }

    // Get Referral type
    $scope.BindRefreltype = function () {
      $scope.SelectedReferral = filterFilter($scope.ReferralTypeList, {
        referral_source: $scope.Patient.referral_type
      });
      console.log($scope.SelectedReferral);
      $scope.SelectedReferral_type_subcats = $scope.SelectedReferral[0].referral_type_subcats;
    }
    $scope.getRelatedPatient();

    //get contact list
    $scope.getContactList = function () {
      $http.get('/patients/related_patients').success(function (list) {
        $scope.ContactList = list;
      })
    }
    $scope.getContactList();

    //create new patient
    $scope.CreatePatient = function (file, data) {
      if(document.getElementById('Auto') != null) {
        var autoChild = document.getElementById('Auto').firstElementChild;
        var el = angular.element(autoChild);
        el.scope().$mdAutocompleteCtrl.hidden = true;
      }
      if (data.dob != null && data.dob != '') {
        var new_Date = new Date(data.dob);
        var booking_month = new_Date.getMonth() + 1;
        var booking_Date = new_Date.getDate();
        if (booking_month < 10)
          booking_month = '0' + booking_month;
        if (booking_Date < 10)
          booking_Date = '0' + booking_Date;
        var booking_new_Date = new_Date.getFullYear() + '-' + booking_month + '-' + booking_Date;
        data.dob = booking_new_Date;
      }
      document.getElementById('patientLogo').style.borderColor = '#37628f';
      if(file && file.size != null && file.size > 2000000){
        $rootScope.errors = [{"error_name" : "Image", "error_msg":"is larger than 2 MB"}];
        $rootScope.showMultyErrorToast();
        document.getElementById('patientLogo').style.borderColor = "red";
        return false;
      }
      $rootScope.cloading = true;
      $http.post('/patients', {
        patient: data
      }).success(function(results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
           //if (file == undefined || file.blobUrl == undefined) {
              $rootScope.cloading = false;
              $state.go('patient-detail', { 'patient_id':results.patient_id});
              $translate('toast.patientAdded', $rootScope.translationData).then(function(msg) {
                $rootScope.showSimpleToast(msg);
              });
            //}
            if (file && file != undefined && file.blobUrl != undefined) {
            $rootScope.cloading = true;
            Upload.upload({
              url: '/patients/' + results.patient_id + '/upload',
              method: 'PUT',
              file: file
            }).progress(function (evt) {
              var progressPercentage = parseInt(100 * evt.loaded / evt.total);
            }).success(function (data, status, headers, config) {
              if (data.error) {
                $rootScope.errors = data.error;
                $rootScope.showMultyErrorToast();
                $rootScope.cloading = false;
              } 
              else {
                $rootScope.cloading = false;
                $state.go('patient-detail', { 'patient_id':results.patient_id});
                $translate('toast.patientAdded', $rootScope.translationData).then(function(msg) {
                  $rootScope.showSimpleToast(msg);
                });
              }
            }).error(function (data, status, headers, config) {
            })
          }

        }
      })
    }

    //delete patient parmanent
    $scope.cntry = '';
    $scope.country = '';

    //get current country
    Data.getCountry().then(function (results) {
      $scope.country = results;
      Data.getCurrentCountry().then(function (cntry) {
        console.log(cntry);
        if($rootScope.commonData.c_code){
          $scope.Patient.country = $rootScope.commonData.c_code;
          $scope.GetStates($scope.Patient.country);
        }
        else{
          $scope.Patient.country = cntry.country;
          $scope.GetStates(cntry.country);
        }
      })
    });

    //get current state
    $scope.GetStates = function(data) {
      $scope.state = 'Select State';
      $scope.Patient.city = '';
      $scope.Patient.postal_code = '';
      Data.getCountry().then(function(results) {
        $scope.countryf = results;
        $scope.Jfilename = filterFilter($scope.countryf, {
          code: data
        });
        Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
            $scope.state = results;

          if ($rootScope.commonData.bs_head_state) {
            //$scope.Patient.state = $rootScope.commonData.bs_head_state;
            $scope.Patient.state = '';
          }
          else{
            //$scope.Patient.state = results[0].code;
          }
        });
      });
    };

    $scope.today = function() {
      $scope.Patient.dob = '';
    };
    $scope.today();

    $scope.clear = function() {
    };

    $scope.open = function($event) {
      $scope.status.opened = true;
    };

    $scope.status = {
      opened: false
    };
  }
]);

app.controller('PatientEditCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$stateParams',
  '$translate',
  '$filter',
  'Upload',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $stateParams, $translate, $filter, Upload) {
    $scope.new_pati = false;
    $scope.maxDate = new Date();
    $scope.header = {
      module:'controllerVeriable.patient',
      title:'controllerVeriable.editPatient',
      back_link: 'patient-detail({"ptient_id" : ' + $stateParams.patient_id + '})'
    }
    $scope.editPatient = true;

    $translate('controllerVeriable.patient', $rootScope.translationData).then(function(msg) {
      $scope.header.module = msg;
    });

    $translate('controllerVeriable.editPatient', $rootScope.translationData).then(function(msg) {
      $scope.header.title = msg;
    });

    //Initialize new blank patient
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

    //open form for new patient
    $scope.new_patient = function () {
      $scope.new_pati = true;
    }

    //hide form for new patient
    $scope.new_patient_Hide = function () {
      $state.go('patient');
    }

    //add relative patient
    $scope.addRelative = function () {
      $scope.Patient.relationship.push({
        patient: '',
        type: 'Parent'
      })
    }

    //remove relative patient
    $scope.removeRelative = function (index) {
      $scope.Patient.relationship.splice(index, 1)
    }

    //add new phone to array
    $scope.addPhone = function () {
      $scope.Patient.patient_contacts_attributes.push({
        contact_no: '',
        contact_type: 'mobile'
      })
    }

    //remove phone from array
    $scope.removePhone = function (index) {
      $scope.Patient.patient_contacts_attributes.splice(index, 1)
    }

    //get referral type
    $scope.getReferralType = function () {
      $http.get('/referrals').success(function (results) {
        $scope.ReferralTypeList = results;
        $scope.BindRefreltype();
      })
    }
    $scope.getReferralType();

    $scope.BindRefreltype = function () {
      $scope.Patient.referrer = '';
      $scope.SelectedReferral = filterFilter($scope.ReferralTypeList, {
        referral_source: $scope.Patient.referral_type
      });
      $scope.SelectedReferral_type_subcats = $scope.SelectedReferral[0].referral_type_subcats;
    }

    //get concession list
    $scope.getConcessionList = function () {
      $http.get('/settings/concession_type').success(function (results) {
        $scope.ConcessionTypeList = results;
        $scope.Patient.concession_type = 'None';
      })
    }
    $scope.getConcessionList();

    //get docters list
    $scope.getDoctorList = function () {
      $http.get('/patients/doctors').success(function (list) {
        $scope.DoctorList = list;
      });
    }
    $scope.getDoctorList();

    //get related patient
    $scope.getRelatedPatient = function () {
      $http.get('/patients/related_patients').success(function (list) {
        $scope.PatientFullList = list;
        $scope.PatientListRefine = [];
        $scope.current_patient = $stateParams.patient_id;
        for (i = 0; i < $scope.PatientFullList.length; i++) {
          if ($scope.PatientFullList[i].id != $scope.current_patient) {
            $scope.PatientListRefine.push({
              first_name: $scope.PatientFullList[i].first_name,
              id: $scope.PatientFullList[i].id,
              last_name: $scope.PatientFullList[i].last_name
            })
          }
        }
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
    $scope.getRelatedPatient();

    //get patient list
    $scope.getPatientList = function () {
      $http.get('/patients').success(function (list) {
        $scope.PatientList = list;
      });
    }
    $scope.getPatientList();

    //get contacts list
    $scope.getContactList = function () {
      $http.get('/referral_types').success(function (list) {
        $scope.ContactList = list;
      })
    }
    $scope.getContactList();

    //update patient data
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
      $http.put('patients/' + data.id, {
        patient: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
        else {
          if (file != null && file.blobUrl == undefined) {
            $state.go('patient-detail', { 'patient_id':$stateParams.patient_id}, { reload: true});
            $rootScope.cloading = false;
            // $scope.$parent.PatientsDetail();
            $translate('toast.patientUpdated', $rootScope.translationData).then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
          if (file == null || file.blobUrl != undefined) {
            $rootScope.cloading = true;
            Upload.upload({
              url: '/patients/' + data.id + '/upload',
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
                $state.go('patient-detail', { 'patient_id':$stateParams.patient_id}, { reload: true});
                $rootScope.cloading = false;
                // $scope.$parent.PatientsDetail();
                $translate('toast.patientUpdated', $rootScope.translationData).then(function (msg) {
                  $rootScope.showSimpleToast(msg);
                });
              }
            }).error(function (data, status, headers, config) {
            })
          }
        }
      })
    }

    $scope.cntry = '';
    $scope.country = '';
    Data.getCountry().then(function (results) {
      $scope.country = results;
    });

    $scope.GetStates = function (data) {
      $scope.state = '';
      $scope.Patient.city = '';
      $scope.Patient.city = '';
      $scope.Patient.postal_code = '';
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
    //get patient detail
    $scope.PatientsDetail = function () {
      $http.get('/patients/' + $stateParams.patient_id + '/edit').success(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          if (data.patient_contacts_attributes == '') {
              data.patient_contacts_attributes = [
                {
                  contact_no: '',
                  contact_type: 'mobile'
                }
              ];
            }
          $scope.patientTempData = data;
          if ($scope.patientTempData.country) {
            Data.getCountry().then(function (results) {
              $scope.countryf = results;
              $scope.Jfilename = filterFilter($scope.countryf, {
                code: $scope.patientTempData.country
              });
              Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
                $scope.state = results;
                if ($scope.patientTempData.logo == '/assets/missing.png') {
                    $scope.patientTempData.temp_logo = $scope.patientTempData.logo;
                    $scope.patientTempData.logo = "";
                }
                setTimeout(function () {
                  $scope.$apply(function () {
                    $scope.Patient = $scope.patientTempData;
                  });
                });
              });
            });
          }
          else {
            setTimeout(function () {
              $scope.$apply(function () {
                $scope.Patient = $scope.patientTempData;
                if ($scope.Patient.referral_type == "Color") {
                  $scope.SelectedReferral_type_subcats = $scope.ReferralTypeList[1].referral_type_subcats
                }
              });
            });
          }
        }
      });
    }
    $scope.PatientsDetail();

    $scope.today = function () {
      $scope.dt = new Date();
    };
    $scope.today();

    $scope.clear = function () {
      $scope.dt = null;
    };

    $scope.open = function ($event) {
      $scope.status.opened = true;
    };

    $scope.status = {
      opened: false
    };

  }
]);

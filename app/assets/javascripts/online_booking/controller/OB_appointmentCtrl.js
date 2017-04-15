var app = angular.module('onlineBooking');

app.controller('OB_appointmentCtrl', [
  '$location',
  '$scope',
  '$rootScope',
  'OB_service',
  '$stateParams',
  '$state',
  '$http',
  '$window',
  '$timeout',
  '$cookies',
    function OB_appointmentCtrl($location, $scope, $rootScope, OB_service, $stateParams, $state, $http , $window , $timeout, $cookies) {
    $scope.patient = {
    }
    var cookiesData = $cookies.get('patient_token');

    var date = moment.unix($stateParams.date);
    var endTime = $stateParams.endTime.split(':');  //getting appointment data
    var appointment = OB_service.getBlankAppointment();
    $scope.appointment = appointment.appointment;

    $scope.makeDob = function(){
        $scope.appointment.new_patient.dob = $scope.appointment.new_patient.birthYear+'-'+$scope.appointment.new_patient.birthMonth+'-'+$scope.appointment.new_patient.birthDay;
        //console.log($scope.appointment.new_patient.dob);
    }
    $scope.appointment.new_patient.remember_me = false;

    $scope.getPatientDetails = function()
    {
        if(cookiesData){
            $http.post('/booking/patient_detail_by_cookie',{'patient_token': cookiesData}).then(function(response){
                $scope.appointment.new_patient = response.data.patient_detail;
                console.log('Patient data : ',$scope.appointment.new_patient);
            });
        }
    }
    $scope.getPatientDetails();

    getResult();
    getCountries();

    $scope.disabled = false ;
    $scope.CreateAppointment = function (data) {
        var new_Date = new Date(date);
        var booking_month = new_Date.getMonth() + 1;
        var booking_new_Date = new_Date.getFullYear() + '-' + booking_month + '-' + new_Date.getDate();
        $scope.$parent.slowLoad = true;
        $scope.disabled = true;
        var appointment_type_id = localStorage.OB_servicesId;
        var user_id = localStorage.OB_practitionerId;
        var business_id = localStorage.OB_businessId;
        data.start_hr = date.hour();
        data.start_min = date.minute();
        data.end_hr = endTime[0];
        data.end_min = endTime[1];
        data.appnt_date = booking_new_Date;
        data.appointment_type_id = appointment_type_id;
        data.user_id = user_id;
        data.business_id = business_id;
        //data.new_patient.contact_no = '1'+ data.new_patient.contact_no;
        if (data.notes != '') {
            data.notes = '[Message from ' + data.new_patient.first_name + ' ' + data.new_patient.last_name + ' : ' + data.notes + ']';
        }
        OB_service.CreateAppointment({
            appointment: data
        }).then(function (results) {
            $scope.disabled = false;
            localStorage.setItem('comp_id' , results.data.comp_id)
            if (results.data.flag) {
                $state.go('booking-confirmed', {
                    appointmentId: results.data.id
                })
            }
            else{
                $rootScope.errors = results.data.error;
                $rootScope.showMultyErrorToast();
            }

            $scope.$parent.slowLoad = false;
        })
    }

    $scope.proVar = {};
    $scope.verifyProvince = function(){
        $scope.comp_id = localStorage.comp_id;
        data = {'first_name' : $scope.appointment.new_patient.first_name, 'last_name' : $scope.appointment.new_patient.last_name, 'email' : $scope.appointment.new_patient.email, 'comp_id' : $scope.comp_id}
        if ($scope.bookingInfo.hide_patient_address) {
            if ($scope.appointment.new_patient.first_name != undefined && $scope.appointment.new_patient.first_name != '' && $scope.appointment.new_patient.last_name != undefined && $scope.appointment.new_patient.last_name != '' && $scope.appointment.new_patient.email != undefined && $scope.appointment.new_patient.email != '' && validateEmail($scope.appointment.new_patient.email)) {
                OB_service.getProvience(data).then(function(result){
                    $scope.proVar = result.data;
                    $scope.appointment.new_patient.country = $scope.proVar.c_code;
                    $scope.updateState();
                });
            }
        }
    }

    function getCountries() {
        OB_service.getCountry().then(function (countries) {
            $scope.countryList = countries;
            // OB_service.getProvience(comp_id).then(function(result){
            //     $scope.appointment.new_patient.country = result.data.c_code;
            //     $scope.updateState();
            // });
            OB_service.getCurrentCountry().then(function (ccode) {
                $scope.appointment.new_patient.country = ccode.country;
                $scope.updateState();
            })
        });
    }

    $scope.updateState = function (ccode) {
        var ccode = $scope.appointment.new_patient.country
        var countries = JSON.parse(localStorage.countries);
        var filename = countries.filter(function (c) {
            return c.code === ccode;
        }) [0].filename;
        if (filename == undefined) {
            $scope.stateList = []
        }
        else {
            OB_service.getStateList(filename).then(function (results) {
                $scope.stateList = results;
                if ($scope.proVar.state) {
                    $scope.appointment.new_patient.state = $scope.proVar.state;
                }
                else{
                    $scope.appointment.new_patient.state = ''
                }
            })
        }
    }

    function validateEmail(email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(email);
    }

    //DOBoptions
    $scope.maxDate = new Date();
    $scope.popup1 = {
        opened: false
    };

    $scope.open1 = function () {
        $scope.popup1.opened = true;
    };

    $scope.getRequest = function(){
        $stateParams.url = window.location;
        var encodedString = btoa($stateParams.url);
        $http.get('/facebook/current_path', {params:{"current_path": encodedString}})
            .then(function(response){
                if(response.data.flag == true){
                    $window.location = 'auth/facebook';
                }
            });
    }

    function getResult(){
        $http.get('/facebook/get_data').then(function(response){
            if (response.data.has_record){
                $scope.appointment.new_patient = response.data;
                $scope.birthDay = response.data.day ;
                $scope.birthMonth = response.data.month ;
                $scope.birthYear = response.data.year ;
                $scope.appointment.new_patient.contact_type = 'mobile' ;
                $scope.appointment.new_patient.reminder_type = 'email' ;
                $scope.appointment.new_patient.profile_pic = response.data.fb_url ;
                $scope.appointment.new_patient.gender = makeFirstCapitalLetter(response.data.gender);
                fb_id  = response.data.fb_detail_id
                $timeout(function(){
                    $http.get('/facebook/remove_data?id='+fb_id).then(function(response){
                        console.log("removed ?" + response.data);
                    });
                }, 5000);
            }
        });
    }

    function makeFirstCapitalLetter(token){
        if (token == null){
            return null
        }else {
            return token.charAt(0).toUpperCase() + token.slice(1);
        }
    }
    }
])

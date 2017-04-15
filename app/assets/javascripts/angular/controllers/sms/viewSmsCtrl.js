app.controller('viewSmsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$filter',
  '$state',
  '$http',
  'filterFilter',
  '$stateParams',
  '$translate',
  function ($rootScope, $scope, Data, $filter, $state, $http, filterFilter, $stateParams, $translate) {
    $scope.header = {
      module:'controllerVeriable.sms',
      title:'controllerVeriable.viewSms',
      back_link: 'smsLogs',
    }
    if ($stateParams.contactType || $stateParams.patientType) {
      $scope.onlyOne = true;
    }
    function getPatientDetail(id) {
      $http.get('/patients/' +id+ '/sms_item').success(function(data){
        console.log(data);
        $scope.patientNo = data;
      });
    }
    function getContactDetail(id) {
      $http.get('/contacts/' +id+ '/sms_item').success(function(data){
        console.log(data);
        $scope.patientNo = data;
      });
    }

      function getUnknownDetail(no) {
          $http.get('/sms_center/custom?unknown_no='+no).success(function(data){
              console.log(data);
              $scope.patientNo = data;
          });
      }

      function getUserDetail(id) {
          $http.get('/settings/users/' +id+ '/sms_items').success(function(data){
              console.log(data);
              $scope.patientNo = data;
          });
      }

      if($stateParams.patientType){
      getPatientDetail($stateParams.patientType)
    }
    if($stateParams.contactType){
      getContactDetail($stateParams.contactType)
    }

      if($stateParams.userType){
          getUserDetail($stateParams.userType)
      }

      if($stateParams.unknownNo){
          getUnknownDetail($stateParams.unknownNo)
      }


      $scope.hitCancel = function(){
      if ($stateParams.patient_id) {
        $state.go('patient-detail', {'patient_id' : $stateParams.patient_id});
      }
      else{
        $state.go('smsLogs');
      }
    }

  }
]);
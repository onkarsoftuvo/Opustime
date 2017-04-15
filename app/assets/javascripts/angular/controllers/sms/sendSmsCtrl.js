app.controller('sendsmsCtrl', [
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
    $scope.send = {};
    $scope.send.message = '';
    $scope.onlyOne = false;
    $scope.trimBox = false;
    if ($stateParams.patient_id || $stateParams.contact_id) {
      $scope.onlyOne = true;
    }
    else{
      $scope.onlyOne = false;
    }
    $scope.header = {
      module:'controllerVeriable.sms',
      title:'controllerVeriable.sendSms',
      back_link: 'sms',
    }
    function getPatientNo(id) {
      $http.get('/patients/' +id+ '/sms_item?num='+ $stateParams.phone_no).success(function(data){
        console.log(data);
        $scope.patientNo = data;
      });
    }

    function getContactNo(id) {
      $http.get('/contacts/' +id+ '/sms_item?num='+ $stateParams.phone_no).success(function(data){
        console.log(data);
        $scope.patientNo = data;
      });
    }

    /*function getMsgHistory(id){
      $http.get('/patients/' +id+ '/sms_item').success(function(data){
        console.log(data);
        $scope.history = data;
      })
    }*/


    if ($stateParams.patient_id) {
      $scope.header.back_link = 'patient-detail({"patient_id" : ' + $stateParams.patient_id + '})';
      getPatientNo($stateParams.patient_id)
      //getMsgHistory($stateParams.patient_id)
    }
    else if($stateParams.contact_id){
      console.log($stateParams.phone_no)
      $scope.header.back_link = 'contact';
      getContactNo($stateParams.contact_id)
    }
    $scope.totalCount = 0;
    $scope.countChar = function(message){
      var countLength = message.split('');
      $scope.totalCount = countLength.length;
    }
    $scope.hitCancel = function(){
      if ($stateParams.patient_id) {
        $state.go('patient-detail', {'patient_id' : $stateParams.patient_id});
      }
      else if($stateParams.contact_id){
        $state.go('contact');
      }
      else{
        $state.go('sms');
      }
    }

    //$scope.messageSendTo = [];
    $scope.$watch('message',function(next, pre){
    })
    var contactID = localStorage.getItem('contactId');
    var recallID = localStorage.getItem('recallId');
    var obj_type = localStorage.getItem('obj_type');
    var filterDate = localStorage.getItem('filter_date');
    // if ($stateParams.patient_id) {
    //   obj_type = 'patient';
    // }
    // else if($stateParams.contact_id){
    //   obj_type = 'contact';
    // }
    // if(obj_type == 'birthdays' || obj_type == 'recalls' || obj_type == 'refers'){
    //   obj_type = 'patient';
    // }

    //$scope.conList = [];
    $scope.getNumbers = function(){
      if(filterDate != 'undefined'){
        console.log('Filter Date: ', filterDate);
        $http.get('/sms_center/patients/get_numbers?obj_type=' + obj_type + '&filterDate=' + filterDate + '&ids=' + contactID + '&recall_ids=' + recallID).success(function(data){
          $scope.allList = data.avail_obj_list;
          $scope.conList = data.avail_obj_list;
          $scope.messageSendTo = data.selected_obj_list;
        })
      }else{
        console.log('Calling without filters');
        $http.get('/sms_center/patients/get_numbers?obj_type=' + obj_type + '&ids=' + contactID + '&recall_ids=' + recallID).success(function(data){
          $scope.allList = data.avail_obj_list;
          $scope.conList = data.avail_obj_list;
          $scope.messageSendTo = data.selected_obj_list;
        })
      }
    }
    if (!$stateParams.patient_id) {
      $scope.getNumbers();
    }

    function remainFilterList(){

    }
    $scope.ContactListf = function(query){
      query = angular.lowercase(query)
      return $filter('filter') ($scope.conList, query)
    }

    function getSmsTemplates(){
      $rootScope.cloading = true;
      $http.get('/settings/sms_templates/list').success(function(data){
        $rootScope.cloading = false;
        $scope.allTemplates = data;
      })
    }
    getSmsTemplates();
    $scope.tempData = {};
    $scope.tempData.tabs = {};
    $scope.tempData.tabs.business = false;
    $scope.tempData.tabs.contact = false;
    $scope.tempData.tabs.practitioner = false;

    function getTampDetail(id) {
      $http.get('/settings/sms_templates/' + id + '/drop_downs_items').success(function (data) {
        console.log(data);
        $scope.tempData = data;
        if ($scope.tempData.tabs.practitioner && $scope.tempData.practitioners.length!=0) {
          $scope.send.prac = data.practitioners[0].id
        }
        if ($scope.tempData.tabs.contact && $scope.tempData.contacts.length!=0) {
          $scope.send.contact = data.contacts[0].id
        }
        if ($scope.tempData.tabs.business && $scope.tempData.locations.length!=0) {
          $scope.send.business = data.locations[0].id
        }
        if($scope.tempData.practitioners.length!=0 || $scope.tempData.contacts.length!=0 || $scope.tempData.locations.length!=0){
          $scope.trimBox = true;
        }
        else{
         $scope.trimBox = false; 
        }
      });
    }

    $scope.bingMessage = function(msg){
      $scope.send.message = msg.body;
      getTampDetail(msg.id)
    }

    function htmlToPlaintext(text) {
      return text ? String(text).replace(/<[^>]+>/gm, ' ') : '';
    }

    $scope.sendMsg = function(data){
      $rootScope.cloading = true;
      $scope.message = data.message;
      $scope.receiver = [];
      if($stateParams.patient_id){
        $scope.receiver.push({'id' : $scope.patientNo.id, 'contact' : $scope.patientNo.number})
      }
      else if($stateParams.contact_id){
        $scope.receiver.push({'id' : $scope.patientNo.id, 'contact' : $scope.patientNo.number})
      }
      else{
        $scope.messageSendTo.forEach(function(messTo){
          $scope.receiver.push({'id' : messTo.id, 'contact' : messTo.contact})
        });
      }
      $scope.sendMsgTo = {'receiver' : $scope.receiver, 'msg' : $scope.message, 'obj_type' : obj_type};
      if(data.prac){
        $scope.sendMsgTo.doctor_id = data.prac;
      }
      if(data.business){
        $scope.sendMsgTo.bs_id = data.business;
      }
      if(data.contact){
        $scope.sendMsgTo.contact_id = data.contact;
      }
      if($stateParams.patient_id){
        $http.post(' /patients/' + $stateParams.patient_id + '/send_sms', $scope.sendMsgTo).success(function (result) {
          $rootScope.cloading = false;
          if (result.flag==true) {
            //$state.go('patient-detail', {'patient_id' : $stateParams.patient_id});
            $scope.send.message = '';
            getPatientNo($stateParams.patient_id)
            $translate('controllerVeriable.messSent').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
          else{
            //$state.go('patient-detail', {'patient_id' : $stateParams.patient_id});
            $rootScope.errors = result.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
      else if($stateParams.contact_id){
        console.log($scope.sendMsgTo);
        $http.post(' /contacts/' + $stateParams.contact_id + '/send_sms', $scope.sendMsgTo).success(function (result) {
          $rootScope.cloading = false;
          if (result.flag==true) {
            //$state.go('contact');
            $scope.send.message = '';
            getContactNo($stateParams.contact_id)
            $translate('controllerVeriable.messSent').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
          else{
            //$state.go('contact');
            $rootScope.errors = result.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
      else{
        $http.post('/sms_center/send_sms', $scope.sendMsgTo).success(function (result) {
          $rootScope.cloading = false;
          if (result.flag==true) {
            $state.go('smsLogs');
            $translate('controllerVeriable.messSent').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
          else{
            $rootScope.errors = result.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
    }
  }
]);
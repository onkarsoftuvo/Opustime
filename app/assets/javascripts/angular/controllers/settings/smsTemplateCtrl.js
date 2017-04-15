app.controller('smsTemplateCtrl', [
  '$scope',
  '$rootScope',
  'Data',
  '$modal',
  '$state',
  function ($scope, $rootScope, Data, $modal, $state) {
    $rootScope.LetterTemplatedeleteText = false;
    $scope.disabled = false;
    //Get Letter Template
    $rootScope.GetSMSTemplate = function () {
      Data.get('/settings/sms_templates').then(function (results) {
        console.log('Here the sms_templates results: ', results);
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.smsTemplateList = results;
        }
      });
    }
    $rootScope.GetSMSTemplate();
    $rootScope.btnText = 'button.update';
    $rootScope.Btnlettertemplate = false;
    //delete popup for confirmation
    $scope.TemplateDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.deleteTemplate());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
  }
]);
app.controller('smsTemplateChildCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$state',
  '$stateParams',
  'Data',
  '$translate',
  function ($scope, $rootScope, $http, $state, $stateParams, Data, $translate) {
    $rootScope.LetterTemplatedeleteText = true;
    if ($stateParams.sms_templates_id == 'new') {
      $rootScope.btnText = 'button.save';
      $rootScope.LetterTemplatedeleteText = true;
      $rootScope.Btnlettertemplate = true;
    } 
    else {
      $rootScope.btnText = 'button.update';
      $rootScope.LetterTemplatedeleteText = false;
      $rootScope.Btnlettertemplate = true;
    }
    //get letter tamplate data

    $scope.getsmstemplatedata = function () {
      //$rootScope.cloading = true;
      if ($stateParams.sms_templates_id != 'new') {
        Data.get('/settings/sms_templates/' + $stateParams.sms_templates_id + '/edit').then(function (results) {
          console.log('Here get the template data: ', results);
          if (results.code) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard');
          }
          else{
              //alert(JSON.stringify (results));
            $scope.smsTemplateItems = results;
          }
        });
      }
    }
    $scope.getsmstemplatedata();
    //save new or update existing latter tamplate
    $scope.smsTemplateSubmit = function (data) {
      data = {'sms_template' : data};
      $rootScope.cloading = true;
      if ($stateParams.sms_templates_id == 'new') {
        $http.post('/settings/sms_templates', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            /*$translate('toast.letterTemplateCreated').then(function (msg) {
	            $rootScope.showSimpleToast(msg);
	          });*/
            $rootScope.btnText = 'button.update';
            $rootScope.LetterTemplatedeleteText = false;
            $state.go('settings.sms-templates.info', {
              sms_templates_id: results.id
            });
            $translate('controllerVeriable.smsTemplate').then(function (msg) {
                $rootScope.showSimpleToast(msg);
            });
            $rootScope.GetSMSTemplate();
            $rootScope.cloading = false;
          }
        });
      } 
      else {
        $http.put('/settings/sms_templates/' + $stateParams.sms_templates_id, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('controllerVeriable.smsTempUpdate').then(function (msg) {
                $rootScope.showSimpleToast(msg);
            });
            $rootScope.GetSMSTemplate();
            $http.get('/settings/sms_templates/' + $stateParams.sms_templates_id + '/edit').success(function (results) {
              $scope.smsTemplateItems = results;
              $rootScope.cloading = false;
            });
            $rootScope.cloading = false;
          }
        });
      }
    }
    //delete letter tamplate
    $rootScope.deleteTemplate = function () {
      $rootScope.cloading = true;
      $http.delete ('/settings/sms_templates/' + $stateParams.sms_templates_id).success(function (results) {
        if (results.error) {
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
        else{
          $translate('controllerVeriable.smsTempDelete').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
        $rootScope.GetSMSTemplate();
        $rootScope.Btnlettertemplate = false;
        $state.go('settings.sms-templates');
        $rootScope.cloading = false;
      });
    }
  }
]);

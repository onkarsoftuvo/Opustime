app.controller('letterTemplateCtrl', [
  '$scope',
  '$rootScope',
  'Data',
  '$modal',
  '$state',
  function ($scope, $rootScope, Data, $modal, $state) {
    $rootScope.LetterTemplatedeleteText = false;
    $scope.disabled = false;
    //Get Letter Template
    $rootScope.GetLetterTemplate = function () {
      Data.get('/letter_templates').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.LetterTemplateList = results;
        }
      });
    }
    $rootScope.GetLetterTemplate();
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
app.controller('letterTemplateChildCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$state',
  '$stateParams',
  'Data',
  '$translate',
  function ($scope, $rootScope, $http, $state, $stateParams, Data, $translate) {
    $rootScope.LetterTemplatedeleteText = true;
    if ($stateParams.letter_templates_id == 'newServ' || $stateParams.letter_templates_id == 'new') {
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

    $scope.getlettertemplatedata = function () {
      $rootScope.cloading = true;
      if ($stateParams.letter_templates_id != 'newServ' || $stateParams.letter_templates_id != 'new') {
        Data.get('/letter_templates/' + $stateParams.letter_templates_id + '/edit').then(function (results) {
          if (results.code) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard');
          }
          else{
            $scope.LetterTemplateItems = results;
            setTimeout(function () {
              $scope.$apply(function () {
                $scope.LetterTemplateItems = results;
                $rootScope.cloading = false;
              });
            });
          }
        });
      }
    }
    $scope.getlettertemplatedata();
    //save new or update existing latter tamplate
    $scope.LetterTemplateSubmit = function (data) {
      $rootScope.cloading = true;
      if ($stateParams.letter_templates_id == 'newServ' || $stateParams.letter_templates_id == 'new') {
        if ($stateParams.bilable_id == 'newServ') {
          data.item_type = true;
        } 
        else if ($stateParams.bilable_id == 'new') {
          data.item_type = false;
        }
        $http.post('/letter_templates', data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.letterTemplateCreated').then(function (msg) {
	            $rootScope.showSimpleToast(msg);
	        });
            $rootScope.GetLetterTemplate();
            $state.go('settings.letter-templates', {
              letter_templates_id: results.id
            });
            $rootScope.cloading = false;
          }
        });
      } 
      else {
        $http.put('/letter_templates/' + $stateParams.letter_templates_id, data).success(function (results) {
          if (results.error) {
            $rootScope.cloading = false;
            $rootScope.errors = results.error;
            $rootScope.showMultyErrorToast();
          } 
          else {
            $translate('toast.letterTemplateUpdated').then(function (msg) {
	            $rootScope.showSimpleToast(msg);
	        });
            $rootScope.GetLetterTemplate();
            $http.get('/letter_templates/' + $stateParams.letter_templates_id + '/edit').success(function (results) {
              $scope.LetterTemplateItems = results;
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
      $http.delete ('/letter_templates/' + $stateParams.letter_templates_id).success(function (results) {
        $translate('toast.letterTemplateDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
        });
        $rootScope.GetLetterTemplate();
        $state.go('settings.letter-templates');
        $rootScope.cloading = false;
      });
    }
    if ($stateParams.letter_templates_id == 'new') {
      $rootScope.btnText = 'button.save';
      $rootScope.Btnlettertemplate = true;
    } 
    else {
      $rootScope.Btnlettertemplate = true;
    }
  }
]);

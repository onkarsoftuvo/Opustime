app.controller('treatmentNoteCtrl', [
  '$timeout',
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  'Upload',
  '$modal',
  '$translate',
  function ($timeout, $scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, Upload, $modal, $translate) {
    //Get TemplateNoteList
    $rootScope.getTemplateList = function () {
      Data.get('/settings/template_notes').then(function (list) {
        if (list.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $rootScope.TemplateNoteList = list;
        }
      });
    }
    //delete treatment note popup

    $scope.treDelete = function (size) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size
      });
    };
    $rootScope.BtnTreatmentNotes = false;
    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.deleteTemplate());
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $scope.upload = function (files) {
      if (files && files.length) {
        for (var i = 0; i < files.length; i++) {
          var file = files[i];
          if (!file.$error) {
            Upload.upload({
              url: '/settings/import/template',
              file: file
            }).success(function (data, status, headers, config) {
              if (data.error) {
                $rootScope.cloading = false;
                $rootScope.errors = data.error;
                $rootScope.showMultyErrorToast();
              } 
              else {
                $timeout(function () {
                  $state.go('settings.treatment-notes.info', {
                    TnoteID: data.id
                  });
                  $rootScope.getTemplateList();
                  $translate('toast.treatmentNoteCreated').then(function (msg) {
      			        $rootScope.showSimpleToast(msg);
      			      });
                });
              }
            });
          }
        }
      }
    };
    // Edit template
    $rootScope.EditTemplate = function () {
      $state.go('settings.treatment-notes.edit', {
        TnoteID: $rootScope.TemplateId
      })
    }
    $rootScope.getTemplateList();
    $rootScope.editDisabled = true;
    $rootScope.updateDisabled = true;
    $rootScope.exportDisabled = true;
    $rootScope.updateBtnTxt = 'button.save';
    $rootScope.cancelBtnTxt = 'button.cancel';
    $rootScope.cancelDislable = true;
    $rootScope.clonebtn = false;
    $scope.cancelNote = function(){
      $rootScope.BtnTreatmentNotes = false;
      $state.go('settings.treatment-notes');
    }
  }
]);
app.controller('treatmentNoteNewCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$translate',
  function ($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $modal, $translate) {
    $scope.template_note = {
      temp_sections_attributes: []
    }
    $rootScope.editDisabled = true;
    $rootScope.exportDisabled = true;
    $rootScope.updateDisabled = false;
    $rootScope.updateBtnTxt = 'button.save';
    $rootScope.cancelBtnTxt = 'button.cancel';
    $rootScope.clonebtn = false;
    $rootScope.cancelDislable = true;
    $rootScope.BtnTreatmentNotes = true;
    $rootScope.templateText = 'settings.treatment_note.newTemplate';
    // Add section
    $scope.addSection = function () {
      $scope.template_note.temp_sections_attributes.push({
        name: '',
        questions_attributes: [
        ]
      })
    }
    // remove section
    $scope.removeSection = function (index) {
      $scope.template_note.temp_sections_attributes.splice(index, 1)
    }
    // Add Query
    $scope.AddQuestion = function (data) {
      $scope.template_note.temp_sections_attributes[data].questions_attributes.push({
        title: '',
        q_type: 'Text',
        quest_choices_attributes: [
          {
            title: ''
          }
        ]
      });
    }
    // remove query
    $scope.RemoveQuestion = function (pindex, index) {
      $scope.template_note.temp_sections_attributes[pindex].questions_attributes.splice(index, 1)
    }
    // Add answer
    $scope.AddAnswer = function (section, question) {
      $scope.template_note.temp_sections_attributes[section].questions_attributes[question].quest_choices_attributes.push({
        title: ''
      });
    }
    // remove answer
    $scope.RemoveAnswer = function (section, question, index) {
      $scope.template_note.temp_sections_attributes[section].questions_attributes[question].quest_choices_attributes.splice(index, 1)
    }
    // change question type
    $scope.ChangeQuestionType = function (data) {
      $scope.template_note.temp_sections_attributes[data].questions_attributes[data].quest_choices_attributes = [
        {
          title: ''
        }
      ];
    }
    if ($stateParams.TnoteID) {
      if ($stateParams.clone) {
        Data.get('/settings/template_notes/' + $stateParams.TnoteID + '/edit?q=clone').then(function (results) {
          if (!results.code) {
            $scope.template_note = results;
            $scope.template_note.name = '';
            $scope.template_note.show_patient_addr = false;
            $scope.template_note.show_patient_dob = false;
            $scope.template_note.show_patient_medicare = false;
            $scope.template_note.show_patient_occup = false;
            $rootScope.getTemplateList();
          }
          $rootScope.cloading = false;
        })
      } 
      else {
        Data.get('/settings/template_notes/' + $stateParams.TnoteID + '/edit').then(function (results) {
          if(!results.code){
            $scope.template_note = results;
            $scope.template_note.name = '';
            $scope.template_note.show_patient_addr = false;
            $scope.template_note.show_patient_dob = false;
            $scope.template_note.show_patient_medicare = false;
            $scope.template_note.show_patient_occup = false;
            $rootScope.getTemplateList();
          }
          $rootScope.cloading = false;
        })
      }
    }
    //Create Treatment Note

    $scope.UpdateTemplate = function (template_note) {
      $rootScope.cloading = true;
      $http.post('/settings/template_notes', {
        'template_note': template_note
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.getTemplateList();
          $state.go('settings.treatment-notes.info', {
            TnoteID: results.template_id
          })
          $translate('toast.treatmentNoteCreated').then(function (msg) {
  	        $rootScope.showSimpleToast(msg);
  	      });
          $rootScope.cloading = false;
        }
      });
    }
  }
]);
app.controller('treatmentNoteInfoCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$modal',
  '$translate',
  function ($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $modal, $translate) {
    $rootScope.editDisabled = false;
    $rootScope.exportDisabled = false;
    $rootScope.updateDisabled = false;
    $rootScope.updateBtnTxt = 'button.clone';
    $rootScope.BtnTreatmentNotes = true;
    $rootScope.cancelBtnTxt = 'button.delete';
    $rootScope.cancelDislable = false;
    $rootScope.clonebtn = true;
    $rootScope.ExportData = function () {
      window.location = '/settings/template_notes/' + $stateParams.TnoteID + '/download';
    }
    $rootScope.deleteTemplate = function() {
      $http.delete ('/settings/template_notes/' + $stateParams.TnoteID).success(function (results) {
        $state.go('settings.treatment-notes');
        $rootScope.getTemplateList();
        $translate('toast.treatmentNoteDeleted').then(function(msg) {
	      $rootScope.showSimpleToast(msg);
	    });
      })
    }
    $rootScope.cloneTemplate = function() {
      $state.go('settings.treatment-notes.clone', {
        TnoteID: $stateParams.TnoteID,
        clone: 'clone'
      })
    }
    $scope.getTemplateInfo = function() {
      $rootScope.cloading = true;
      Data.get('/settings/template_notes/' + $stateParams.TnoteID).then(function(results) {
        if (!results.code) {
          if (results.error) {
            $state.go('settings.treatment-notes');
            $rootScope.showErrorToast(results.error);
          } 
          else {
            $scope.Templateinfo = results;
            $rootScope.getTemplateList();
            $rootScope.cloading = false;
          }
        }
      })
    }
    $rootScope.TemplateId = $stateParams.TnoteID;
    $scope.getTemplateInfo();
  }
]);

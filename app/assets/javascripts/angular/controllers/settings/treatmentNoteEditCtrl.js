app.controller('treatmentNoteEditCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  '$translate',
  function($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, $translate) {
    $rootScope.editDisabled = true;
    $rootScope.exportDisabled = true;
    $rootScope.updateDisabled = false;
    $rootScope.updateBtnTxt = 'button.update';
    $rootScope.cancelBtnTxt = 'button.cancel';
    $rootScope.clonebtn = false;
    $rootScope.templateText = 'button.editing'
    $scope.removed_ans = [];
    $scope.removed_que = [];
    $rootScope.cancelDislable = true;
    // Add Section
    $scope.addSection = function() {
      $scope.template_note.temp_sections_attributes.push({
        name: '',
        questions_attributes: []
      })
    }
    // remove Section
    $scope.removeSection = function(index) {
      $scope.template_note.temp_sections_attributes.splice(index, 1)
    }
    // Add Question
    $scope.AddQuestion = function(data) {
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
    // Remove Question
    $scope.RemoveQuestion = function(pindex, index, id) {
      $scope.template_note.temp_sections_attributes[pindex].questions_attributes.splice(index, 1)
    }
    // add answer
    $scope.AddAnswer = function(section, question) {
      $scope.template_note.temp_sections_attributes[section].questions_attributes[question].quest_choices_attributes.push({
        title: ''
      });
    }
    // remove answer
    $scope.RemoveAnswer = function(section, question, index, id) {
      $scope.template_note.temp_sections_attributes[section].questions_attributes[question].quest_choices_attributes.splice(index, 1)
    }
    // change question type
    $scope.ChangeQuestionType = function(data) {
      $scope.template_note.temp_sections_attributes[data].questions_attributes[data].quest_choices_attributes = [
        {
          title: ''
        }
      ];
    }
    //Get Template List

    $scope.getTemplateInfo = function () {
      $rootScope.cloading = true;
      Data.get('/settings/template_notes/' + $stateParams.TnoteID + '/edit').then(function (results) {
        $scope.template_note = results;
        $rootScope.getTemplateList();
        $rootScope.cloading = false;
      })
    }
    $rootScope.TemplateId = $stateParams.TnoteID;
    $scope.getTemplateInfo();
    //Update Template Note
    $scope.UpdateTemplate = function (template_note) {
      $rootScope.cloading = true;
      $http.put('/settings/template_notes/' + $stateParams.TnoteID, {
        'template_note': template_note
      }).success(function(results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.getTemplateList();
          $translate('toast.treatmentNoteUpdated').then(function (msg) {
    		    $rootScope.showSimpleToast(msg);
    		  });
          $state.go('settings.treatment-notes.info', {
            TnoteID: results.template_id
          })
          $rootScope.cloading = false;
        }
      });
    }
  }
]);

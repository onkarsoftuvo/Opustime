app.controller('treatmentNoteModuleCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  'treatData',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, treatData, $translate) {
    $scope.showLoading = false;
    $rootScope.patientCurrentId=treatData.patientId;
    $scope.addNewNote = true;
    if ($rootScope.appPerm.managetr_note_add){
        $scope.addNewTreatmentNote = true ;
    }else{
        $scope.addNewTreatmentNote = false ;
    }
    if ($rootScope.appPerm.managetr_note_view && $rootScope.appPerm.managetr_note_add == false ){
        $scope.previous_notes = true;
    }else{
        $scope.previous_notes = false;
    }
    if (($rootScope.appPerm.managetr_note_add == false) && ($rootScope.appPerm.managetr_note_view == false)){
        $scope.attachments = true;
    }else{
        $scope.attachments=false;
    }

    $scope.hideCopyLink = false;
    $scope.Getformat={}
    $scope.Getformat.treatment_note={};
    $scope.addNew=function(){
      $scope.addNewNote = true;
      $scope.addNewTreatmentNote=true;
      $scope.previous_notes=false;
      $scope.attachments=false;
      $scope.GetTamplateList();
    }
    $scope.getPrevious=function(){
      $scope.addNewTreatmentNote=false;
      $scope.previous_notes=true;
      $scope.attachments=false;
    }
    $scope.getAtachments=function(){
      $scope.addNewTreatmentNote=false;
      $scope.previous_notes=false;
      $scope.attachments=true;
    }
    $rootScope.getPatientData=function(){
      $http.get('/appointments/' + treatData.patientId + '/treatment_notes/details').success(function (data) {
        $scope.patientDetail=data;
      });
    }
    $rootScope.getPatientData();

    //appointment listing
    $scope.getAppointmentList=function(){
      $http.get('/patients/' + treatData.patientId + '/treatment_notes/appointments').success(function (data) {
        $scope.appointmentList=data.patient_appointments;
        console.log('Here the data: ', $scope.appointmentList);
      });
    }
    $scope.getAppointmentList();

    $scope.TreatmentPrint = function (id) {
      $modalInstance.dismiss('cancel');
      var win = window.open('/treatment_notes/' + id + '/generate_pdf.pdf', '_blank');
      win.focus();
    }

    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    $scope.GetTamplateList = function () {
      $http.get('/appointments/' + treatData.appointment_id + '/template_notes').success(function (data) {
        $scope.GetList = data.notes;
        if ($scope.tamplateNoteId == undefined) {
          data.notes.forEach(function(list){
            if(list.id == data.selected_note){
              $rootScope.GetFirstElement = list.name;
            }
          });
          $scope.GetTamplateFormat(data.selected_note);
        }
        $scope.noteTamplate = data.selected_note;
      });
    }
    $scope.GetTamplateList();
    $scope.GetTamplateFormat = function (id) {
      $scope.noteTamplate=id;
      $scope.showLoading = true;
      $scope.hideCopyLink = false;
      $http.get('/template_notes/' + id + '/template_format').success(function (data) {
        $scope.Getformat = data;
        $scope.showLoading = false;
        if($rootScope.currentAppointment){
          $scope.Getformat.treatment_note.appointment_id = ($rootScope.currentAppointment).toString();
        }
      });
    }
    //save Treatment Note

    $scope.saveTretementNote = function (data, isFinal) {
      $rootScope.cloading = true;
      data.treatment_note.appointment_id=parseInt(data.treatment_note.appointment_id);
      data.treatment_note.save_final = isFinal;
      data.treatment_note.treatment_notes_template_note_attributes = {
        template_note_id: $scope.noteTamplate
      };
      $http.post('/patients/' + treatData.patientId + '/treatment_notes', data).success(function (data) {
        if (data.flag) {
          $modalInstance.dismiss('cancel');
          $scope.GetTamplateList();
          $translate('toast.treatmentNoteAdded').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
          $rootScope.getEvents();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = data.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
        }
      });
    }
    //Edit Treatment Note
    $scope.editTreatmentNote=function(id){
      $scope.addNewNote = false;
      $scope.addNewTreatmentNote=true;
      $scope.previous_notes=false;
      $scope.attachments=false;
      $scope.showLoading = true;
      $http.get('/treatment_notes/' + id + '/edit').success(function (data) {
        $scope.Getformat = data;
        $scope.getpreNote = data.treatment_note.id;
        $rootScope.GetFirstElement = $scope.Getformat.treatment_note.title;
        if($scope.Getformat.treatment_note.appointment_id!=null){
          $scope.Getformat.treatment_note.appointment_id=$scope.Getformat.treatment_note.appointment_id.toString();
        }
        else{
          $scope.Getformat.treatment_note.appointment_id='null';
        }
        
        $scope.showLoading = false;
        $scope.noteTamplate = data.treatment_note.treatment_notes_template_note_attributes.template_note_id;
      });
    }
    //Update Treatment Note

    $scope.updateTretementNote = function (data, isFinal) {
      if(data.treatment_note.appointment_id!='null'){
        data.treatment_note.appointment_id=parseInt(data.treatment_note.appointment_id);
      }
      else{
        data.treatment_note.appointment_id=null;
      }
      data.treatment_note.save_final = isFinal;
      data.treatment_note.treatment_notes_template_note_attributes = {
        template_note_id: $scope.noteTamplate
      };
      $http.put('/treatment_notes/' + $scope.getpreNote, data).success(function (data) {
        if (data.flag) {
          $scope.showLoading = false;
          $modalInstance.dismiss('cancel');
          $scope.GetTamplateList();
          $translate('toast.treatmentNoteUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
      });
    }

    //get previous note
    $scope.getPreviousNote = function () {
      $scope.showLoading = true;
      $http.get('/patients/' + treatData.patientId + '/template_notes/' + $scope.noteTamplate + '/previous_treatment_note').success(function (data) {
        $scope.Getformat = data;
        $scope.Getformat.treatment_note.appointment_id = ($rootScope.currentAppointment).toString();
        $scope.hideCopyLink = true;
        $scope.showLoading = false;
      });
    }

    //Delete Treatment Notes
    $scope.deleteNotes_Confirm = function (id) {
      $scope.Notes_ID = id;
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteTreatment.html',
        controller: 'DeleteTreatmentCtrl',
        size: 'sm'
      });
    };
    $scope.deleteNotes = function (id) {
      $rootScope.cloading = true;
      $http.delete ('/treatment_notes/' + id).success(function (data) {
        if (data.flag) {
          $translate('toast.treatmentNoteDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
          $rootScope.cloading = false;
          $rootScope.getPatientData();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
        }
      });
    }
    $rootScope.confirmDelete = function () {
      $rootScope.modalInstance.close($scope.deleteNotes($scope.Notes_ID));
    };

    //Delete Attachment

    $scope.deleteAttachment = function (id) {
      $scope.Attachment_ID = id;
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteAttachment.html',
        controller:'DeleteTreatmentCtrl',
        size: 'sm'
      });
    };
    $rootScope.confirmDeleteAttachment = function () {
      $rootScope.modalInstance.close($scope.DeleteAttachment($scope.Attachment_ID));
    };
    $scope.DeleteAttachment = function (id) {
      $rootScope.cloading = true;
      $http.delete ('/file_attachments/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $rootScope.getPatientData();
          $translate('toast.attachmentDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
        }
      })
    }

    //edit attachment
    $scope.editAttachment = function (id) {
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'attachmentEdit.html',
        controller:'attEditCtrl',
        size: 'sm attachments_popup',
        resolve: {
          elementId: function () {
            return id;
          }
        }
      });
    };

    $scope.addFile = function () {
      $scope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'fileAttach.html',
        controller: 'fileAttachCtrler',
        size: 'email-xl'
      });
    };
  }
]);
app.controller('DeleteTreatmentCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
  }
]);
app.controller('attEditCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$modalInstance',
  '$stateParams',
  'elementId',
  '$filter',
  '$translate',
  function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter, $translate) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
    //get attachment data

    $scope.currentAtachment = elementId;
    $scope.attachmentData = function () {
      $rootScope.cloading = true;
      $scope.showLoading = true;
      $http.get('/file_attachments/' + $scope.currentAtachment + '/edit').success(function (data) {
        $scope.attachmentData = data;
        $rootScope.cloading = false;
        $scope.showLoading = false;
      });
    }
    $scope.attachmentData();
    //update attachment
    $scope.updateAttachment = function (data) {
      $scope.showLoading = true;
      $http.put('/file_attachments/' + $scope.currentAtachment + '?description=' + data.description).success(function (data) {
        if (data.flag) {
          $modalInstance.dismiss('cancel');
          $rootScope.getPatientData();
          $translate('toast.attachmentUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $scope.showLoading = false;
          $rootScope.getEvents();
        } 
        else {
          $modalInstance.dismiss('cancel');
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          $scope.showLoading = false;
        }
      });
    }
  }
]);
/*File Attatch Modal Ctrl */
app.controller('fileAttachCtrler', [
  '$scope',
  '$rootScope',
  '$http',
  '$modalInstance',
  'Upload',
  '$rootScope',
  '$stateParams',
  '$translate',
  function ($scope, $rootScope, $http, $modalInstance, Upload, $rootScope, $stateParams, $translate) {
    // upload on file select or drop
    $scope.uploadingFile = false;
    /*$scope.upload = function (file) {
      $scope.uploadingFile = true;
      $scope.uploadedName = file.name;
      Upload.upload({
        url: '/patients/' + $rootScope.patientCurrentId + '/files/upload',
        method: 'POST',
        file: file
      }).progress(function (evt) {
        $scope.CurrentlyUploading = true;
        $scope.UploadedSuccessfully = false;
        $scope.progressPercentage = 0;
        $scope.progressPercentage = parseInt(100 * evt.loaded / evt.total);
        if ($scope.progressPercentage == 100)
        {
          $scope.CurrentlyUploading = false;
          $scope.UploadedSuccessfully = true;
          $scope.ErrorWhileUpload = false;
          $modalInstance.dismiss('cancel');
          $rootScope.getPatientData();
          $translate('toast.attachmentImported').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getEvents();
        }
      }).success(function (data, status, headers, config, evt) {
        if (data.error) {
          $rootScope.errors = data.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
          $scope.progressPercentage = 0;
          $scope.CurrentlyUploading = false;
          $scope.UploadedSuccessfully = false;
          $scope.ErrorWhileUpload = true;
        } 
        else {
          $rootScope.cloading = false;
          $rootScope.getPatientData();
        }
      }).error(function (data, status, headers, config) {
      })
    };*/

     $scope.upload = function (files) {
        console.log(files)
        $scope.uploadingFile = true;
        console.log($scope.uploadedName);
        if (files != undefined) {
            for (i = 0; i < files.length; i++) {
                $scope.uploadedName = files.name;
                file = files[i];
                console.log(file)
                Upload.upload({
                    url: '/patients/' + $rootScope.patientCurrentId + '/files/upload',
                    method: 'POST',
                    file: file
                }).progress(function (evt) {
                    $scope.CurrentlyUploading = true;
                    $scope.UploadedSuccessfully = false;
                    $scope.progressPercentage = 0;
                    $scope.progressPercentage = parseInt(100 * evt.loaded / evt.total);
                    if ($scope.progressPercentage == 100) {
                        $scope.CurrentlyUploading = false;
                        $scope.UploadedSuccessfully = true;
                        $scope.ErrorWhileUpload = false;
                    }
                }).success(function (data, status, headers, config, evt) {
                    if (data.error) {
                        $rootScope.errors = data.error;
                        $modalInstance.dismiss('cancel');
                        $rootScope.getPatientData();
                        $rootScope.showMultyErrorToast();
                        $rootScope.cloading = false;
                        $scope.progressPercentage = 0;
                        $scope.CurrentlyUploading = false;
                        $scope.UploadedSuccessfully = false;
                        $scope.ErrorWhileUpload = true;
                    }
                    else {
                      $rootScope.getPatientData();
                      $modalInstance.dismiss('cancel');
                      $translate('toast.attachmentImported').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                      });
                        /*if (files.length == i) {
                          $scope.uploadCom()
                        }
                        $rootScope.cloading = false;*/
                    }
                })
            }
        }
    }
    
    /*$scope.uploadCom = function(){
      $rootScope.CountClientFile();
      $modalInstance.dismiss('cancel');
      $rootScope.filterClientFiles($rootScope.ChkData);
      $translate('toast.attachmentImported').then(function (msg) {
        $rootScope.showSimpleToast(msg);
      });
    }*/


    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
  }
]);
app.controller('PatientDetailCtrl', [
    '$rootScope',
    '$scope',
    '$state',
    '$http',
    '$modal',
    '$stateParams',
    '$translate',
    'filterFilter',
    function ($rootScope, $scope, $state, $http, $modal, $stateParams, $translate, filterFilter) {
        $scope.PatientDetails;
        $scope.PatientsDetail = function (called) {
            $http.get('/patients/' + $stateParams.patient_id).success(function (data) {
                // console.log('Here the patient detail: ', data);
                if (data.code) {
                    $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
                    $state.go('dashboard');
                }
                else{
                    $scope.PatientDetails = data;
                    $scope.current_patient_id = data.id;
                    $scope.filter = data.filter;
                    if(!called){
                        $rootScope.filterClientFiles($scope.filter);
                    }
                    if (data.status === 'active') {
                        $scope.ArchiveCheck = false;
                        $scope.Archive = true;
                        $scope.Delete = false;
                        //$rootScope.cloading = false;
                    }
                    else
                    {
                        $scope.ArchiveCheck = true;
                        $scope.Delete = true;
                        $scope.Archive = false;
                        $scope.someDate = data.updated_at;
                        //$rootScope.cloading = false;
                    }
                    var addPracti = false;
                    var addBuis = false;
                    $scope.nextAppointment = function ()
                    {
                        var addPracti = false;
                        $http.get('/appointments/' + $scope.PatientDetails.next_appointment_info.appointment_id).success(function (data) {
                            var app_detail = data.appointment;
                            var StoredBuis = localStorage.getItem('savedBusiness');
                            if (app_detail.business != StoredBuis) {
                                localStorage.setItem('savedBusiness', app_detail.business);
                            }
                            var StoredDr = localStorage.getItem('allDoctors');
                            StoredDr = StoredDr.split(',');
                            for (i = 0; i < StoredDr.length; i++)
                            {
                                if (app_detail.practitioner_id != StoredDr[i])
                                {
                                    addPracti = true;
                                }
                            }
                            if (addPracti) {
                                StoredDr.push(app_detail.practitioner_id);
                                localStorage.setItem('allDoctors', StoredDr);
                            }
                            localStorage.setItem('savedview', 'agendaThreeDay');
                            $state.go('appointment.appDate', {
                                'appointment_date': app_detail.appnt_date_only,
                                'appointment_id': $scope.PatientDetails.next_appointment_info.appointment_id
                            });
                        });
                    }
                }
            });
        };

        $scope.appointmentClicked = function (id) {
            var addPracti = false;
            $http.get('/appointments/' + id).success(function (data) {
                var app_detail = data.appointment;
                var StoredBuis = localStorage.getItem('savedBusiness');
                if (app_detail.business != StoredBuis) {
                    localStorage.setItem('savedBusiness', app_detail.business);
                }
                var StoredDr = localStorage.getItem('allDoctors');
                StoredDr = StoredDr.split(',');
                for (i = 0; i < StoredDr.length; i++)
                {
                    if (app_detail.practitioner_id != StoredDr[i])
                    {
                        addPracti = true;
                    }
                }
                if (addPracti) {
                    StoredDr.push(app_detail.practitioner_id);
                    localStorage.setItem('allDoctors', StoredDr);
                }
                localStorage.setItem('savedview', 'agendaThreeDay');
                $state.go('appointment.appDate', {
                    'appointment_date': app_detail.appnt_date_only,
                    'appointment_id': id
                });
            });
        }

        $scope.userRole = function () {
            $http.get('/patients/get/authority').success(function (data) {
                $rootScope.roleData = data;
            });
        };
        $scope.userRole();

        $scope.historyReport = function ()
        {
            var win = window.open('/patients/' + $stateParams.patient_id + '/account_history.pdf', '_blank');
            win.focus();
        };

        //lazy loading function
        var lazydo = true;
        $scope.LazyLoad = function ()
        {
            $scope.slowLoad = true;
            if ($scope.nexthit == null) {
                $scope.slowLoad = false;
            }
            if ($scope.nexthit != null && lazydo)
            {
                lazydo = false;
                $http.get($scope.nexthit).success(function (data) {
                    $scope.nexthit = data.next_hit;
                    $scope.PatientsClientFiles.modules = $scope.PatientsClientFiles.modules.concat(data.modules);
                    $scope.slowLoad = false;
                    setTimeout(function () {
                        lazydo = true;
                    }, 5000);
                });
            }
        };

        $scope.PatientsDetail();
        $rootScope.Showmedicalalert = true;
        $rootScope.angledown = true;
        $scope.CommDetail = function (data) {
            $scope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'ComDetail.html',
                controller: 'ComDetailCtrl',
                size: 'md',
                resolve: {
                    data: function () {
                        return data;
                    }
                }
            });
        };

        $scope.patientDelete = function (size) {
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteModal.html',
                size: 'sm',
            });
        };

        $scope.PatientsAlertDetail = function () {
            $http.get('/patients/' + $stateParams.patient_id + '/medical_alerts').success(function (data) {
                $scope.PatientAlertList = data;
            });
        };

        $scope.medical_alert = {};
        $scope.PatientsAlertDetail();
        $scope.AlertPatient = function (data) {
            $http.post('/patients/' + $stateParams.patient_id + '/medical_alerts', {
                medical_alert: data
            }).success(function (results) {
                $scope.medical_alert.alertName = '';
                $rootScope.Showmedicalalert = true;
                $rootScope.alertform = false;
                $scope.PatientsAlertDetail();
                $scope.alertform = false;
                $scope.Showmedicalalert = true;
            });
        };

        $scope.UpdatePatientalert = function (data, id) {
            $http.put('/medical_alerts/' + id, {
                medical_alert: data
            }).success(function (results) {
                $rootScope.Showmedicalalert = true;
                $rootScope.alertform = false;
                $scope.PatientsAlertDetail();
            });
        };

        $scope.DeleteAlert = function (id) {
            $http.delete ('/medical_alerts/' + id).success(function (results) {
                $scope.PatientsAlertDetail();
            });
        };

        //$scope.originForm = angular.copy($scope.medical_alert);
        $rootScope.Showmedicalalert = true;
        $rootScope.alertform = false;
        $rootScope.anchorpatientalert = true;
        $rootScope.okdelete = function () {
            $rootScope.modalInstance.close($rootScope.ArchiveDelete());
        };

        $rootScope.cancel = function () {
            $rootScope.modalInstance.close();
        };

        $scope.Getarchive = function () {
            $rootScope.cloading = true;
            $http.get('/patients/' + $stateParams.patient_id).success(function (data) {
                if (data.status === 'active') {
                    $scope.ArchiveCheck = false;
                    $scope.Archive = true;
                    $scope.Delete = false;
                    $rootScope.cloading = false;
                }
                else
                {
                    $scope.ArchiveCheck = true;
                    $scope.Delete = true;
                    $scope.Archive = false;
                    $scope.someDate = data.updated_at;
                    $rootScope.cloading = false;
                }
            });
        };

        //Delete
        $rootScope.ArchiveDelete = function () {
            $http.put('/patients/' + $stateParams.patient_id + '/delete_permanent').success(function (data) {
                $state.go('patient');
                $translate('toast.patientDeleted', $rootScope.translationData).then(function (msg) {
                    $rootScope.showSimpleToast(msg);
                });
            });
        };

        //Archive Again
        $scope.Activeagian = function () {
            $http.put('/patients/' + $stateParams.patient_id + '/active').success(function (data) {
                $scope.Getarchive();
            });
        };

        $scope.archive = function () {
            $scope.ArciveStatus = 'true';
            $http.delete ('/patients/' + $stateParams.patient_id).success(function (data) {
                $scope.Getarchive();
            });
        };

        $scope.createApp = function(patient_id, title, fName, lName){
            if(title == null)
            {
                title = '';
            }
            localStorage.setItem('newPatientId', patient_id);
            var patient_name = title +' ' + fName + ' ' + lName;
            localStorage.setItem('newPatientName', patient_name);
            $state.go('appointment');
        }

        $scope.merge = function (size) {
            $scope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'merge.html',
                controller: 'mergeCtrl',
                size: 'new-xl',
                resolve: {
                    cplane: function () {
                        return $scope.cplane;
                    }
                }
            });
        };

        $scope.a = 'a';
        $scope.PatientPopup = function (type, size, elementId) {
            if (type == 'newLetter') {
                $http.get('/patients/' + $stateParams.patient_id + '/letters/letter_templates').success(function (data) {
                    if (data == '') {
                        $rootScope.showErrorToast('Please create letter template');
                        $rootScope.cloading = false;
                    } else {
                        $scope.modalInstance = $modal.open({
                            animation: $scope.animationsEnabled,
                            templateUrl: type + '.html',
                            controller: type + 'Ctrl',
                            size: size,
                            resolve: {
                                elementId: function () {
                                    return elementId;
                                }
                            }
                        });
                    }
                });
            } else {
                $scope.modalInstance = $modal.open({
                    animation: $scope.animationsEnabled,
                    templateUrl: type + '.html',
                    controller: type + 'Ctrl',
                    size: size,
                    resolve: {
                        elementId: function () {
                            return elementId;
                        }
                    }
                });
            }
        };

        if (localStorage.getItem('emailPatient')) {
            $scope.PatientPopup('newLetter', 'email-xl');
            localStorage.removeItem('emailPatient');
        }

        //Get full detail of petient
        $scope.noRecord = false;
        $rootScope.filterClientFiles = function (data) {
            //$scope.PatientsDetail(true)
            $rootScope.ChkData = data;
            $rootScope.cloading = true;
            var filterurl = '';
            var i = 0;
            angular.forEach(data, function (value, key) {
                if (value == true) {
                    if (i > 0) {
                        filterurl += ',' + key;
                    }
                    else if (i == 0) {
                        filterurl += key;
                    }
                    i++;
                }
            });
            $http.get('/patients/' + $stateParams.patient_id + '/client_profile?filter=' + filterurl).success(function (data) {
                $scope.PatientsClientFiles = data;
                $scope.nexthit = data.next_hit;
                console.log('data', data);
                $rootScope.cloading = false;
                if ($scope.PatientsClientFiles.modules.length == 0) {
                    $scope.noRecord = true;
                }
                else {
                    $scope.noRecord = false;
                }
            });
        };

        //print invoice
        $scope.PrintInvoice = function (id) {
            var win = window.open('/invoices/' + id + '/print.pdf', '_blank');
            win.focus();
        };

        //print payment
        $scope.PrintPayment = function (id) {
            var win = window.open('/payments/' + id + '/print.pdf', '_blank');
            win.focus();
        };

        //print letter
        $scope.ForLetterPrint = function (id) {
            var win = window.open('/letters/' + id + '/print.pdf', '_blank');
            win.focus();
        };

        //print treatment Note
        $scope.TreatmentPrint = function (id) {
            var win = window.open('/treatment_notes/' + id + '/generate_pdf.pdf', '_blank');
            win.focus();
        };

        //Download letter as PDF
        $scope.ForLetterDownload = function (id) {
            var win = window.open('/letters/' + id + '/print.pdf?download=true', '_blank');
            win.focus();
        };

        $scope.editPaitentInvoice = function(id){
            $state.go('patient-detail.editInvoice',{invoice_id:id});
        }

        //select all filter
        $scope.selectAll = function () {
            $rootScope.cloading = true;
            $scope.filter.appointment = true;
            $scope.filter.treatment_note = true;
            $scope.filter.invoice = true;
            $scope.filter.payment = true;
            $scope.filter.recall = true;
            $scope.filter.file = true;
            $scope.filter.letter = true;
            $scope.filter.communication = true;
            var filterurl = 'appointment,treatment_note,invoice,payment,recall,file,letter,communication';
            $http.get('/patients/' + $stateParams.patient_id + '/client_profile?filter=' + filterurl).success(function (data) {
                $scope.PatientsClientFiles = data;
                $rootScope.cloading = false;
                if ($scope.PatientsClientFiles.modules.length == 0) {
                    $scope.noRecord = true;
                }
                else {
                    $scope.noRecord = false;
                }
            });
        };

        //clear all filters
        $scope.clearAll = function () {
            $scope.filter = {
            };
            $scope.noRecord = true;
            $rootScope.filterClientFiles();
        };

        //Get total count of client files
        $rootScope.CountClientFile = function () {
            $rootScope.cloading = true;
            $http.get('/patients/' + $stateParams.patient_id + '/submodules').success(function (data) {
                $scope.CountClientFiles = data;
                $rootScope.cloading = false;
            });
        };
        $rootScope.CountClientFile();

        //Delete Treatment Notes
        $scope.deleteNotes_Confirm = function (id) {
            $rootScope.Notes_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteTreatment.html',
                size: 'sm',
            });
        };

        $rootScope.deleteTreatmentNotes = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/treatment_notes/' + id).success(function (data) {
                if (data.flag) {
                    $translate('toast.treatmentNoteDeleted', $rootScope.translationData).then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        };

        $rootScope.confirmDelete = function () {
            $rootScope.modalInstance.close($rootScope.deleteTreatmentNotes($rootScope.Notes_ID));
        };

        //get recall data
        $scope.getRecallDate = function (is_selected, id) {
            $rootScope.cloading = true;
            $http.get('/recalls/' + id + '/set_recall_date?is_selected=' + is_selected).success(function (data) {
                $rootScope.cloading = false;
                $rootScope.filterClientFiles($rootScope.ChkData);
            });
        };

        //Delete Recall
        $scope.deleteRecall_Confirm = function (id) {
            $rootScope.Recall_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteRecall.html',
                size: 'sm',
            });
        };

        $rootScope.confirmDeleteRecall = function () {
            $rootScope.modalInstance.close($rootScope.deleteRecall($rootScope.Recall_ID));
        };

        $rootScope.deleteRecall = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/recalls/' + id).success(function (data) {
                if (data.flag) {
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $translate('toast.recallDeleted', $rootScope.translationData).then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        };

        //Delete payment
        $scope.deletePayment = function (id) {
            $rootScope.Payment_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeletePayment.html',
                size: 'sm',
            });
        };

        $rootScope.confirmDeletePayment = function () {
            $rootScope.modalInstance.close($rootScope.DeletePayment($rootScope.Payment_ID));
        };

        $rootScope.DeletePayment = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/payments/' + id).success(function (results) {
                if (results.error) {
                    $rootScope.cloading = false;
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                }
                else {
                    $rootScope.cloading = false;
                    $rootScope.CountClientFile();
                    $translate('toast.paymentDeleted', $rootScope.translationData).then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
            });
        };

        //Delete invoice
        $scope.deleteInvoice = function (id) {
            $rootScope.Invoice_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteInvoice.html',
                size: 'sm',
            });
        };

        $rootScope.confirmDeleteInvoice = function () {
            $rootScope.modalInstance.close($rootScope.DeleteInvoice($rootScope.Invoice_ID));
        };

        $rootScope.DeleteInvoice = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/invoices/' + id).success(function (results) {
                if (results.error) {
                    $rootScope.cloading = false;
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                }
                else {
                    $rootScope.cloading = false;
                    $rootScope.CountClientFile();
                    $translate('toast.invoiceDeleted').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
            });
        };

        //Delete Attachment
        $scope.deleteAttachment = function (id) {
            $rootScope.Attachment_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteAttachment.html',
                size: 'sm',
            });
        };

        $rootScope.confirmDeleteAttachment = function () {
            $rootScope.modalInstance.close($rootScope.DeleteAttachment($rootScope.Attachment_ID));
        };

        $rootScope.DeleteAttachment = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/file_attachments/' + id).success(function (results) {
                if (results.error) {
                    $rootScope.cloading = false;
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                }
                else {
                    $rootScope.cloading = false;
                    $rootScope.CountClientFile();
                    $translate('toast.attachmentDeleted').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
            });
        };

        //Delete Letter
        $scope.deleteLetter = function (id) {
            $rootScope.Letter_ID = id;
            $rootScope.modalInstance = $modal.open({
                animation: $scope.animationsEnabled,
                templateUrl: 'DeleteLetter.html',
                size: 'sm',
            });
        };

        $rootScope.confirmDeleteLetter = function () {
            $rootScope.modalInstance.close($rootScope.deleteLetter($rootScope.Letter_ID));
        };

        $rootScope.deleteLetter = function (id) {
            $rootScope.cloading = true;
            $http.delete ('/letters/' + id).success(function (data) {
                if (data.flag) {
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $translate('toast.letterDeleted').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        };

        $scope.cancel = function () {
            $rootScope.modalInstance.close();
        };

        //send Email Invoice
        $scope.SendInvoiceEmail = function (id) {
            $rootScope.cloading = true;
            $http.get('/invoices/' + id + '/send_email?email_to=patient').success(function (results) {
                if (results.flag) {
                    $rootScope.cloading = false;
                    $translate('toast.emailSentSuccess').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                }
                else {
                    $translate('toast.somthingWentWrong').then(function (msg) {
                        $rootScope.showMultyErrorToast(msg);
                    });
                }
            });
        };

        $scope.addZero = function (i) {
            if (i < 10) {
                i = '0' + i;
            }
            return i;
        };

        //get logs and make all logs messages
        $scope.appIds = [
        ];
        $scope.showLog = function (id) {
            $scope.logs_load = true;
            var logMessages = [
            ];
            var innerMessages = [
            ];
            $http.get('/appointments/' + id + '/logs').success(function (results) {
                $scope.logs = results.logs;
                for (i = 0; i < results.logs.length; i++) {
                    var msg = '';
                    if (results.logs[i].created_at) {
                        msg = results.logs[i];
                        logMessages.push({
                            msg : msg
                        });
                    }
                }
            });
            $scope.appIds.push({
                'id': id,
                logMessages: logMessages
            });
            $scope.logs_load = false;
        };

        $scope.hideLog = function (id) {
            angular.forEach($scope.appIds, function (item) {
                if (item.id == id) {
                    $scope.appIds.splice($scope.appIds.indexOf(item), 1);
                }
            });
        }

        $scope.checkStatus = function (appId) {
            var filteredArray = filterFilter($scope.appIds, {
                id: appId
            });
            if (filteredArray.length != 0) {
                return true;
            }
            else {
                return false;
            }
        }
    }
]);

/*File Attatch Modal Ctrl */
app.controller('fileAttachCtrl', [
    '$scope',
    '$http',
    '$modalInstance',
    'Upload',
    '$rootScope',
    '$stateParams',
    '$translate',
    '$window',
    function ($scope, $http, $modalInstance, Upload, $rootScope, $stateParams, $translate, $window) {
        // upload on file select or drop
        $scope.uploadingFile = false;
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
                        url: '/patients/' + $stateParams.patient_id + '/files/upload',
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
                            $rootScope.showMultyErrorToast();
                            $rootScope.cloading = false;
                            $scope.progressPercentage = 0;
                            $scope.CurrentlyUploading = false;
                            $scope.UploadedSuccessfully = false;
                            $scope.ErrorWhileUpload = true;
                        }
                        else {
                            if (files.length == i) {
                                $scope.uploadCom()
                            }
                            $rootScope.cloading = false;
                        }
                    })
                }
            }
        }

        $scope.uploadCom = function(){
            $rootScope.CountClientFile();
            $modalInstance.dismiss('cancel');
            $rootScope.filterClientFiles($rootScope.ChkData);
            $translate('toast.attachmentImported').then(function (msg) {
                $rootScope.showSimpleToast(msg);
            });
        }
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
    }
]);

app.controller('addTreatmentNoteCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$translate',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $translate) {
        $scope.showLoading = false;
        $scope.tamplateNoteId = elementId;
        $scope.addNewNote = true;

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }

        $scope.GetTamplateList = function () {
            $http.get('/patients/' + $stateParams.patient_id + '/treatment_notes/template_notes').success(function (data) {
                $scope.GetList = data;
                if ($scope.tamplateNoteId == undefined) {
                    $rootScope.GetFirstElement = $scope.GetList[0].name;
                    $scope.GetTamplateFormat($scope.GetList[0].id);
                }
                $scope.noteTamplate = $scope.GetList[0].id;
            });
        }
        $scope.GetTamplateList();

        $scope.GetTamplateFormat = function (id) {
            $scope.showLoading = true;
            $scope.hideCopyLink = false;
            $http.get('/template_notes/' + id + '/template_format').success(function (data) {
                $scope.Getformat = data;
                $scope.showLoading = false;
            });
        }

        //save Treatment Note
        $scope.saveTretementNote = function (data, isFinal) {
            // console.log('Here the data to save: ',data, 'and final: ', isFinal);
            $rootScope.cloading = true;
            data.treatment_note.save_final = isFinal;
            data.treatment_note.treatment_notes_template_note_attributes = {
                template_note_id: $scope.noteTamplate
            };
            $http.post('/patients/' + $stateParams.patient_id + '/treatment_notes', data).success(function (data) {
                if (data.flag) {
                    $modalInstance.dismiss('cancel');
                    $scope.GetTamplateList();
                    $translate('toast.treatmentNoteAdded').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        }

        //Update Treatment Note
        $scope.updateTretementNote = function (data, isFinal) {
            $scope.showLoading = true;
            data.treatment_note.save_final = isFinal;
            data.treatment_note.treatment_notes_template_note_attributes = {
                template_note_id: $scope.noteTamplate
            };
            $http.put('/treatment_notes/' + $scope.getpreNote, data).success(function (data) {
                if (data.flag) {
                    $scope.showLoading = false;
                    $modalInstance.dismiss('cancel');
                    $scope.GetTamplateList();
                    $rootScope.CountClientFile();
                    $translate('toast.treatmentNoteUpdated').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                }
            });
        }

        //Edit Treatment Note
        $scope.GetTamplateData = function (id) {
            $scope.showLoading = true;
            $http.get('/treatment_notes/' + $scope.tamplateNoteId + '/edit').success(function (data) {
                $scope.Getformat = data;
                $scope.getpreNote = data.treatment_note.id;
                $rootScope.GetFirstElement = $scope.Getformat.treatment_note.title;
                $scope.showLoading = false;
                $scope.noteTamplate = data.treatment_note.treatment_notes_template_note_attributes.template_note_id;
            });
        }
        if ($scope.tamplateNoteId != undefined) {
            $scope.addNewNote = false;
            $scope.GetTamplateData();
        }
        else {
            $scope.addNewNote = true;
        }
        $scope.hideCopyLink = false;

        //get previous note
        $scope.getPreviousNote = function () {
            $scope.showLoading = true;
            $http.get('/patients/' + $stateParams.patient_id + '/template_notes/' + $scope.noteTamplate + '/previous_treatment_note').success(function (data) {
                $scope.Getformat = data;
                $scope.hideCopyLink = true;
                $scope.showLoading = false;
            });
        }
    }
]);

app.controller('mergeCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'filterFilter',
    '$translate',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, filterFilter, $translate) {
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }    //Get Recal Type

        $rootScope.showLoading = true;
        $scope.getMergeList = function () {
            $rootScope.cloading = true;
            $http.get('/patients/' + $stateParams.patient_id + '/identical').success(function (data) {
                $scope.MergeList = data;
                $rootScope.showLoading = false;
                $rootScope.cloading = false;
            });
        }
        $scope.getMergeList();
        //Add identical patient to list
        $scope.mergePatientPost = function () {
            $rootScope.cloading = true;
            var mergelist = $scope.MergeList.identical_patients;
            var identical_patients = filterFilter(mergelist, {
                identicalPatient: true
            });
            var id = [
            ];
            identical_patients.forEach(function (patient) {
                id.push(patient.id)
            })
            $http.post('/patients/' + $stateParams.patient_id + '/merge', {
                identical_patients: id
            }).success(function (results) {
                if (results.flag) {
                    $rootScope.cloading = false;
                    $modalInstance.dismiss('cancel');
                    $translate('toast.patientMergeSuccess').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
            })
        }
    }
]);
app.controller('smsModalCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$filter',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter) {
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
    }
]);
app.controller('recallCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$filter',
    '$translate',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter, $translate) {
        $scope.onlyNumber = function (element) {
        }
        $scope.recallBtns = true;
        $scope.recallId = elementId;
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
        $scope.recallData = {
            recall: {
                recall_types_recall_attributes: {
                    recall_type_id: ''
                }
            }
        };
        //Get Recal Type
        $scope.getRecallType = function () {
            $rootScope.cloading = true;
            $http.get('/settings/recall_types').success(function (data) {
                $scope.RecallList = data;
                $rootScope.cloading = false;
                $scope.first_element = $scope.RecallList[0].id;
                $scope.recallData.recall.recall_types_recall_attributes.recall_type_id = $scope.RecallList[0].id;
                $scope.getMoreInfo($scope.first_element);
            });
        }
        $scope.getRecallType();
        //get recall data at
        $scope.getMoreInfo = function (id) {
            var selectedReacall = $filter('filter') ($scope.RecallList, id)
            if (selectedReacall[0].period_name == 'Month(s)') {
                var d = new Date();
                var months = d.getMonth() + Number(selectedReacall[0].period_val)
                d.setMonth(months);
                $scope.recallData.recall.recall_on_date = d;
            }
            if (selectedReacall[0].period_name == 'Week(s)') {
                var now = new Date();
                var nextWeek = new Date(now);
                var weeksdayscount = Number(selectedReacall[0].period_val) * 7
                nextWeek.setDate(nextWeek.getDate() + weeksdayscount);
                $scope.recallData.recall.recall_on_date = nextWeek;
            }
            if (selectedReacall[0].period_name == 'Day(s)') {
                var now = new Date();
                var nextdate = new Date(now);
                var dayscount = Number(selectedReacall[0].period_val);
                nextdate.setDate(nextdate.getDate() + dayscount);
                $scope.recallData.recall.recall_on_date = nextdate;
            }
        }
        $scope.open = function ($event) {
            $scope.opened = true;
        };
        //save recall type
        $scope.addRecall = function (data) {
            $rootScope.cloading = true;
            $http.post('/patients/' + $stateParams.patient_id + '/recalls', data).success(function (data) {
                if (data.flag) {
                    $modalInstance.dismiss('cancel');
                    $translate('toast.recallAdded').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        }
        if ($scope.recallId != undefined) {
            $scope.recallBtns = false;
        }
        else {
            $scope.recallBtns = true;
        }    //get racall data

        $scope.getRecallData = function () {
            $rootScope.cloading = true;
            $rootScope.showLoading = true;
            $http.get(' /recalls/' + $scope.recallId + '/edit').success(function (data) {
                $scope.recallData = data;
                $rootScope.cloading = false;
                $rootScope.showLoading = false;
            });
        }
        if ($scope.recallId != undefined) {
            $scope.getRecallData();
        }    //update Recall

        $scope.updateRecall = function (data) {
            $scope.showLoading = true;
            $http.put('/recalls/' + data.recall.id, data).success(function (data) {
                if (data.flag) {
                    $scope.showLoading = false;
                    $modalInstance.dismiss('cancel');
                    $rootScope.CountClientFile();
                    $translate('toast.recallUpdated').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                }
            });
        }
    }
]);
app.controller('newEmailCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$filter',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter) {
        $scope.recallBtns = true;
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
    }
]);
app.controller('newLetterCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$filter',
    '$translate',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter, $translate) {
        $scope.letterId = elementId;
        $scope.letterBtns = true;
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }    /*get all tamplates*/

        $scope.letterTamplate = function () {
            $rootScope.cloading = true;
            $scope.showLoading = true;
            $http.get('/patients/' + $stateParams.patient_id + '/letters/letter_templates').success(function (data) {
                $scope.letterTamplateList = data;
                $rootScope.cloading = false;
                $scope.showLoading = false;
                $scope.letterTamplate = $scope.letterTamplateList[0].id;
                if ($scope.letterId == undefined) {
                    $scope.GetLetterFormat($scope.letterTamplate);
                }
            });
        }
        $scope.letterTamplate();
        /*get all letter data*/
        $scope.GetLetterFormat = function (id) {
            $rootScope.cloading = true;
            $scope.showLoading = true;
            $scope.letterId = id;
            $http.get('/letter_templates/' + id + '/letter_detail').success(function (data) {
                $scope.letterTamplateData = data;
                if (data.tabs_info.contact.count > 0)
                {
                    var s = data.tabs_info.contact[0].id;
                }
                $rootScope.cloading = false;
                $scope.showLoading = false;
            });
        }
        $scope.refessh_content = function (pre, con, bus) {
            $http.get('/letter_templates/' + $scope.letterId + '/letter_detail?business_id=' + bus + '&contact_id=' + con + '&practitioner_id=' + pre).success(function (data) {
                $scope.letterTamplateData.letter.content = data.letter.content;
                $rootScope.cloading = false;
                $scope.showLoading = false;
            });
        }    /*save letter*/

        $scope.saveLetter = function (data) {
            $http.post('/patients/' + $stateParams.patient_id + '/letters', {
                letter: data.letter
            }).success(function (data) {
                if (data.flag) {
                    $modalInstance.dismiss('cancel');
                    $translate('toast.letterAdded').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        }    /*edit letter data*/

        $scope.GetLetterData = function () {
            $scope.letterBtns = false;
            $rootScope.cloading = true;
            $scope.showLoading = true;
            $http.get('/letters/' + $scope.letterId + '/edit').success(function (data) {
                $rootScope.LetterID = data.letter.id;
                $scope.letterTamplateData = data;
                $rootScope.cloading = false;
                $scope.showLoading = false;
                $scope.letterUpdateId = $scope.letterTamplateData.letter.id;
            });
        }    /*Update letter*/

        $scope.UpdateLetter = function (data) {
            $rootScope.cloading = true;
            data.letter.id = $rootScope.LetterID;
            $http.put('/letters/' + $rootScope.LetterID, {
                letter: data.letter
            }).success(function (data) {
                if (data.flag) {
                    $modalInstance.dismiss('cancel');
                    $translate('toast.letterUpdated').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.CountClientFile();
                    $rootScope.cloading = false;
                    $rootScope.filterClientFiles($rootScope.ChkData);
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                }
            });
        }
        if ($scope.letterId != undefined) {
            $scope.GetLetterData();
        }
    }
]);

app.controller('ComDetailCtrl', [
    '$scope',
    '$http',
    '$modalInstance',
    'data',
    function ($scope, $http, $modalInstance, data) {
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
        $scope.CommDetails = data;
    }
]);

app.controller('letteremailCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    '$stateParams',
    'elementId',
    '$filter',
    '$translate',
    function ($scope, $rootScope, $http, $modalInstance, $stateParams, elementId, $filter, $translate) {
        $scope.letterID = elementId;
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }    //get letter info to be sent

        $scope.GetLetterInfo = function () {
            $rootScope.cloading = true;
            $scope.showLoading = true;
            $http.get('/letters/' + $scope.letterID + '/info').success(function (data) {
                $scope.letterData = data;
                $scope.letterData.format = 'true';
                $scope.patientEmail = $scope.letterData.send_to.patient_email;
                $scope.contactEmail = $scope.letterData.send_to.contact_email;
                $scope.docterEmail = $scope.letterData.send_to.contact_email;
                $scope.currentEmail = $scope.letterData.recepient_list[0].recepeint_email;
                $rootScope.cloading = false;
                $scope.showLoading = false;
            });
        }
        $scope.check = {
        };
        $scope.GetLetterInfo();
        $scope.custom_emails = false;
        $scope.custom_email = false;
        $scope.enableCustomEmail = function () {
            if ($scope.custom_email == true) {
                $scope.custom_email = false;
            }
            else {
                $scope.custom_email = true;
            }
        }    //making clone for new email

        $scope.addNewRecipient = function () {
            $scope.letterData.custom_email.push({
                email: ''
            });
        }
        $scope.removeCurrent = function (index) {
            $scope.letterData.custom_email.splice(index, 1);
        }
        $scope.selectFrom = function (email) {
            $scope.letterData.from = email;
        }
        $scope.temp = true;
        //sending letter as an email
        $scope.sendLetter = function (ldata) {
            var data = angular.copy(ldata);
            if ($scope.check.PatientEmail) {
                data.send_to.patient_email = $scope.patientEmail;
            }
            else {
                data.send_to.patient_email = '';
            }
            if ($scope.check.ContactEmail) {
                data.send_to.contact_email = $scope.contactEmail;
            }
            else {
                data.send_to.contact_email = '';
            }
            if ($scope.check.DocterEmail) {
                data.send_to.refer_doc = $scope.docterEmail;
            }
            else {
                data.send_to.refer_doc = '';
            }
            if (data.format == 'true') {
                data.format = true;
            }
            else {
                data.format = false;
            }
            $rootScope.cloading = true;
            $scope.showLoading = true;
            $http.post(' /letter/send_email', data).success(function (data) {
                if (data.flag) {
                    $modalInstance.dismiss('cancel');
                    $rootScope.filterClientFiles($rootScope.ChkData);
                    $translate('toast.emailSentSuccess').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $rootScope.cloading = false;
                    $scope.showLoading = false
                }
                else {
                    $modalInstance.dismiss('cancel');
                    $rootScope.errors = results.error;
                    $rootScope.showMultyErrorToast();
                    $rootScope.cloading = false;
                    $scope.showLoading = false;
                }
            });
        }
    }
]);

app.controller('RemoveTreatmentCtrl', [
    '$scope',
    '$rootScope',
    '$http',
    '$modalInstance',
    function ($scope, $http, $modalInstance, $rootScope) {
        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        }
        $rootScope.confirmit = function (data) {
            $rootScope.modalInstance.close($rootScope.deleteTreatmentNotes($rootScope.Notes_ID));
        }
    }
]);

app.controller('attachmentEditCtrl', [
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
        }    //get attachment data

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
                    $rootScope.filterClientFiles($rootScope.ChkData);
                    $translate('toast.attachmentUpdated').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });
                    $scope.showLoading = false
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

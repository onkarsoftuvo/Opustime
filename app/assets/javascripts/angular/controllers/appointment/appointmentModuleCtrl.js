app.controller('appointmentModuleCtrl', [
    '$rootScope',
    '$scope',
    'Data',
    '$state',
    '$http',
    'filterFilter',
    '$modal',
    '$filter',
    '$timeout',
    '$compile',
    'uiCalendarConfig',
    '$uibModal',
    'weekService',
    'monthNameService',
    '$q',
    'Auth',
    'appointmentServe',
    '$translate',
    '$window' ,
    function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $filter, $timeout, $compile, uiCalendarConfig, $uibModal, weekService, monthNameService, $q, Auth, appointmentServe, $translate, $window) {
        $scope.openMenu = false;
        $scope.noPrac = true;
        $rootScope.endTimeError = false;
        $scope.beforeExpand = true;
        $scope.openedMenu = false;
        $scope.showClose = false;
        $rootScope.reSchedule=false;
        $rootScope.reScheduleUnavail=false;
        $rootScope.reScheduleData=null;
        $rootScope.anotherApp=false;
        $rootScope.anotherAppData=null;
        var UserSettings = {};
        var currentUser = localStorage.currentUser;
        if(localStorage.UserSettings == undefined){
            UserSettings[currentUser] = {};
            localStorage.setItem('UserSettings', JSON.stringify(UserSettings))
        }

        UserSettings = JSON.parse(localStorage.UserSettings);
        if(UserSettings[currentUser] == undefined){
            UserSettings[currentUser] = {};
            localStorage.setItem('UserSettings', JSON.stringify(UserSettings))
        }

        /*For active class*/
        $scope.addActiveCalender = false;
        $scope.addActivePra = false;
        $scope.addActiveWait = false;
        $scope.addActiveFilter = false;
        $scope.PractitionerRadio = false;
        $scope.PractitionerCheckbox = false;
        $scope.filterCheckbox = false;
        $scope.waitList = false;
        $scope.calenderOpen = false;
        if (localStorage.getItem('sideBarState')) {
            $scope.openMenu = true;
            $scope.beforeExpand = false;
            $scope.openedMenu = true;
            $scope.showClose = true;
            if (localStorage.getItem('sideBarState') == 'calendar') {
                $scope.addActiveCalender = true;
                $scope.addActivePra = false;
                $scope.addActiveWait = false;
                $scope.addActiveFilter = false;
                $scope.PractitionerRadio = false;
                $scope.PractitionerCheckbox = false;
                $scope.filterCheckbox = false;
                $scope.waitList = false;
                $scope.calenderOpen = true;
            }
            else if (localStorage.getItem('sideBarState') == 'waitlist') {
                $scope.addActiveCalender = false;
                $scope.addActivePra = false;
                $scope.addActiveWait = true;
                $scope.addActiveFilter = false;
                $scope.PractitionerRadio = false;
                $scope.PractitionerCheckbox = false;
                $scope.filterCheckbox = false;
                $scope.waitList = true;
                $scope.calenderOpen = false;
            }
            else if (localStorage.getItem('sideBarState') == 'filters') {
                $scope.addActiveCalender = false;
                $scope.addActivePra = false;
                $scope.addActiveWait = false;
                $scope.addActiveFilter = true;
                $scope.PractitionerRadio = false;
                $scope.PractitionerCheckbox = false;
                $scope.filterCheckbox = true;
                $scope.waitList = false;
                $scope.calenderOpen = false;
            }
        }
        $scope.openCalender = function(){
            $scope.openMenu = true;
            $scope.beforeExpand = false;
            $scope.openedMenu = true;
            $scope.showClose = true;
            /*For active class*/
            $scope.addActiveCalender = true;
            $scope.addActivePra = false;
            $scope.addActiveWait = false;
            $scope.addActiveFilter = false;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = false;
            $scope.waitList = false;
            $scope.calenderOpen = true;
            localStorage.setItem('sideBarState', 'calendar');
        };
        $scope.openWaitList = function () {
            $scope.openMenu = true;
            $scope.beforeExpand = false;
            $scope.openedMenu = true;
            $scope.showClose = true;
            /*For active class*/
            $scope.addActiveCalender = false;
            $scope.addActivePra = false;
            $scope.addActiveWait = true;
            $scope.addActiveFilter = false;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = false;
            $scope.waitList = true;
            $scope.calenderOpen = false;
            localStorage.setItem('sideBarState', 'waitlist');
        };
        $scope.openFilter = function () {
            $scope.openMenu = true;
            $scope.beforeExpand = false;
            $scope.openedMenu = true;
            $scope.showClose = true;
            /*For active class*/
            $scope.addActiveCalender = false;
            $scope.addActivePra = false;
            $scope.addActiveWait = false;
            $scope.addActiveFilter = true;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = true;
            $scope.waitList = false;
            $scope.calenderOpen = false;
            localStorage.setItem('sideBarState', 'filters');
        };
        /*tabbing*/
        $scope.calenderTabbing = function () {
            /*For active class*/
            $scope.addActiveCalender = true;
            $scope.addActivePra = false;
            $scope.addActiveWait = false;
            $scope.addActiveFilter = false;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = false;
            $scope.waitList = false;
            $scope.calenderOpen = true;
            localStorage.setItem('sideBarState', 'calendar');
        };
        $scope.waitlistTabbing = function () {
            /*For active class*/
            $scope.addActiveCalender = false;
            $scope.addActivePra = false;
            $scope.addActiveWait = true;
            $scope.addActiveFilter = false;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = false;
            $scope.waitList = true;
            $scope.calenderOpen = false;
            localStorage.setItem('sideBarState', 'waitlist');
        };
        $scope.filterTabbing = function () {
            /*For active class*/
            $scope.addActiveCalender = false;
            $scope.addActivePra = false;
            $scope.addActiveWait = false;
            $scope.addActiveFilter = true;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = true;
            $scope.waitList = false;
            $scope.calenderOpen = false;
            localStorage.setItem('sideBarState', 'filters');
        };
        /*close side menu*/

        $scope.closeSideMenu = function () {
            $scope.openMenu = false;
            $scope.beforeExpand = true;
            $scope.openedMenu = false;
            $scope.showClose = false;
            /*For active class*/
            $scope.addActiveCalender = false;
            $scope.addActivePra = false;
            $scope.addActiveWait = false;
            $scope.addActiveFilter = false;
            $scope.PractitionerRadio = false;
            $scope.PractitionerCheckbox = false;
            $scope.filterCheckbox = false;
            $scope.waitList = false;
            $scope.calenderOpen = false;
            localStorage.removeItem('sideBarState');
        };
        var date = new Date();
        var d = date.getDate();
        var m = date.getMonth();
        var y = date.getFullYear();
        var h = date.getHours();
        var time = date.getTimezoneOffset();
        // TO Show tooltip on appointment hover
        var tooltip = $('<div/>').qtip({
            id: 'fullcalendar',
            prerender: false,
            overwrite: false,
            content: {
                text: ' ',
                title: {button: true}
            },
            position: {
                corner: {
                    target: 'leftMiddle',
                    tooltip: 'rightMiddle'
                },
                my: 'top right',
                at: 'left top',
                target: 'event',
                viewport: $('.fc-view-container'),
                adjust: {
                    method: 'flip shift',
                    mouse: true,
                    scroll: true,
                    screen: true,
                    resize: true,
                }
            },
            show: false,
            hide: false,
            style: 'qtip-light',
        }).qtip('api');
        $scope.eventSource = {
            className: 'gcal-event' // an option!
        };
        //get apointment list
        $scope.events = [];
        /* event source that calls a function on every view switch */
        $scope.eventsF = function (start, end, timezone, callback, resources) {
            var s = new Date(start).getTime() / 1000;
            var e = new Date(end).getTime() / 1000;
            var m = new Date(start).getMonth();
            var events = $scope.events;
            callback(events);
        };

        //get all permissions
        function getPermissions(){
            $http.get('/appointments/security_roles').success(function(data){
                $rootScope.appPerm = data;
                $rootScope.invPerm = data.invoice_prmsn;
                $rootScope.tr_custom_class = 'col col-sm-'+data.managetr_note_class_index ;
                $rootScope.managetr_note_add = data.managetr_note_add;
                $rootScope.managetr_note_view = data.managetr_note_view;
                $rootScope.file_tab = data.file_tab;

            });
        }
        getPermissions();

        //wait list popup
        $scope.waitListModal = function () {
            var modalInstance = $uibModal.open({
                templateUrl: 'waitListModal.html',
                controller: 'waitListModalCtrl',
                size: 'large_modal waitList_modal',
                windowClass: "modal in",
            });
        };

        //Delete wait list popup
        $scope.openDeletePopup = function (id,events) {
            events.preventDefault();
            events.stopPropagation();
            var modalInstance = $uibModal.open({
                templateUrl: 'waitListconfirmation.html',
                controller: 'waitListconfirmationCtrl',
                windowClass: "modal in",
                size: 'sm',
                resolve: {
                    listId: function () {
                        return id;
                    }
                }
            });
        };

        $rootScope.unavailableActivate=false;

        //unavailable functions
        $scope.addUnavailable=function(){
            $rootScope.availableActivate=false;
            if ($rootScope.unavailableActivate==false) {
                $rootScope.unavailableActivate=true;
            }
            else{
                $rootScope.unavailableActivate=false;
            }
        };
        $rootScope.availableActivate=false;

        //unavailable functions
        $scope.addAvailable=function(){
            $rootScope.unavailableActivate=false;
            if ($rootScope.availableActivate==false) {
                $rootScope.availableActivate=true;
            }
            else{
                $rootScope.availableActivate=false;
            }
        };

        //Unavailable Block popup
        $scope.openUnavailPopup = function () {
            var modalInstance = $uibModal.open({
                templateUrl: 'unavailBlock.html',
                controller: 'unavailBlockCtrl',
                size: 'large_modal waitList_modal',
                windowClass: "modal in",
            });
        };

        //add wait list popup
        $scope.addWaitListModal = function () {
            var modalInstance = $uibModal.open({
                templateUrl: 'addWaitListModal.html',
                controller: 'addWaitListModalCtrl',
                size: 'large_modal waitList_modal',
                windowClass: "modal in",
            });
        };

        //edit wait list popup
        $scope.editWaitList = function (id, e) {
            e.preventDefault();
            e.stopPropagation();
            var modalInstance = $uibModal.open({
                templateUrl: 'addWaitListModal.html',
                controller: 'editWaitListCtrl',
                size: 'large_modal waitList_modal',
                windowClass: "modal in",
                resolve: {
                    listId: function () {
                        return id;
                    }
                }
            });
        };

        //first appointment popup
        $scope.firstAppoinment = function (event, jsEvent, view) {
            tooltip.hide();
            clearTimeout();
            $rootScope.currentAppointment=event.id;
            if(event.app_indication=="_un_app"){
                var modalInstance = $uibModal.open({
                    templateUrl: 'unavailableBlock.html',
                    controller: 'unavailableBlockCtrl',
                    size: 'large_modal firstAppoinment',
                    windowClass: "modal in",
                    resolve: {
                        event: function () {
                            return event.id;
                        }
                    }
                });
            }
            else{
                var modalInstance = $uibModal.open({
                    templateUrl: 'firstAppoinment.html',
                    controller: 'firstAppoinmentCtrl',
                    size: 'large_modal firstAppoinment',
                    windowClass: "modal in",
                    resolve: {
                        event: function () {
                            return event.id;
                        }
                    }
                });
            }
        };

        if (localStorage.getItem('currentAppointment')) {
            var curApp = {};
            curApp.id = localStorage.getItem('currentAppointment');
            localStorage.removeItem('currentAppointment');
            $scope.firstAppoinment(curApp);
        }

        $scope.alertOnDrop = function (event, delta, revertFunc, jsEvent, ui, view) {
            if($rootScope.appPerm.modify){
                var modalInstance = $uibModal.open({
                    templateUrl: 'confirmationModal.html',
                    controller: 'confirmationModalCtrl',
                    windowClass: "modal in",
                    size: 'sm',
                    resolve: {
                        event: function () {
                            return event;
                        }
                    }
                });
            }
            else{
                $rootScope.showErrorToast('Sorry you dont have permissions to modify');
                $rootScope.getEvents();
            }
        };

        /* add and removes an event source of choice */
        $scope.addRemoveEventSource = function (sources, source) {
            var canAdd = 0;
            angular.forEach(sources, function (value, key) {
                if (sources[key] === source) {
                    sources.splice(key, 1);
                    canAdd = 1;
                }
            });
            if (canAdd === 0) {
                sources.push(source);
            }
        };

        // To add delay to tooltip
        $scope.eventMouseover1 = function (data, event, view) {
            if(data.app_indication=="_un_app"){
                t = setTimeout(function () {
                }, 500);
            }
            else{
                var lastTimeMouseMoved = new Date().getTime();
                t = setTimeout(function () {
                    if(data.id){
                        var currentTime = new Date().getTime();
                        if (currentTime - lastTimeMouseMoved) {
                            $scope.eventMouseover(data, event, view);
                        }
                    }
                }, 500);
            }
        };
        $scope.addZero= function(i) {
            if (i < 10) {
                i = "0" + i;
            }
            return i;
        };
        $translate(['qtip.treatmentNoteAddedAsDraft', 'qtip.treatmentNoteAddedAsFinal', 'qtip.appNoteAvail', 'qtip.invoicePaid', 'qtip.outstandingInvoice', 'qtip.arrived', 'qtip.notArrived', 'qtip.completed', 'qtip.notCompleted', 'qtip.pending', 'qtip.absent']).then(function (translations) {
            $scope.treatmentNoteDraft = translations['qtip.treatmentNoteAddedAsDraft'];
            $scope.treatmentNoteFinal = translations['qtip.treatmentNoteAddedAsFinal'];
            $scope.appointmentNote = translations['qtip.appNoteAvail'];
            $scope.invoicePaid = translations['qtip.invoicePaid'];
            $scope.outstandingInvoice = translations['qtip.outstandingInvoice'];
            $scope.arrivedBtn = translations['qtip.arrived'];
            $scope.notArrivedBtn = translations['qtip.notArrived'];
            $scope.CompletedBtn = translations['qtip.completed'];
            $scope.notCompleteBtn = translations['qtip.notCompleted'];
            $scope.pendingBtn = translations['qtip.pending'];
            $scope.absentBtn = translations['qtip.absent'];
        });

        // To show tooltip on mouse hover on any Appointment
        $scope.eventMouseover = function (data, event, view) {
            var startDay = data.start._d.getUTCDate();
            var startMonth = data.start._d.getUTCMonth();
            var startYear = data.start._d.getUTCFullYear();
            var dayName = data.start._d.getUTCDay();
            var Day_Name = weekService.week(dayName);
            var MonthName = monthNameService.month(startMonth);
            var startDate = Day_Name + ', ' + startDay + ' ' + MonthName + ' ' + startYear;
            var startHours = $scope.addZero(data.start._d.getHours());
            var startMin = $scope.addZero(data.start._d.getMinutes());
            var startTime = startHours + ':' + startMin;
            var StartDate = data.start._d;
            var endDate = data.end._d;
            var endHours = $scope.addZero(data.end._d.getHours());
            var endMin = $scope.addZero(data.end._d.getMinutes());
            var endTime = endHours + ':' + endMin;
            var appointment_type_name = data.appointment_type_name;
            var color = data.color;
            var docter = data.docter;
            var totalTime = moment.utc(moment(endDate).diff(moment(StartDate))).format('mm');
            var patient_gender = data.patient_gender;
            var associated_treatment_note_status = data.associated_treatment_note_status;
            if(data.reference_number == null){
                data.reference_number = 'NA';
            }
            if (data.profile_pic_flag == true){
                attach_img = '<img src="' + data.profile_pic + '">' ;
            } else{
                attach_img = '<img src="assets/user.png" class="male" ng-if="'+patient_gender+'">' +
                '<img src="assets/user_female.png" class="female" ng-if="'+patient_gender+'">' +
                '<img src="assets/user_not_app.png" class="not_app" ng-if="'+patient_gender+'">';
            }

            if((data.associated_treatment_note_status != null && data.associated_treatment_note_status == true)) {
                var content =  attach_img +
                    '<h4>' + data.title + '</h4>' +
                    '<h3>With ' + docter + '</h3>' +
                    '<p class="start_date">' + startDate + '<br />' +
                    '<p class="start_time">' + startTime + ' To ' + endTime +' ('+data.total_duration+')'+ '</p>' +
                    '<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + appointment_type_name + '</h6>' +
                    '<div class="notes_indications"><span><p class="green_clr"><i class="fa fa-file-text-o"></i>'+ $scope.treatmentNoteFinal +  ' </p></span>' +'<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + 'Reference# '+data.reference_number + '</h6>' +
                    '<div class="notes_indications">'+
                    '<p class="green_clr is_notes_avail"  ng-if="'+data.is_notes_avail+'"><i class="fa fa-calendar"></i> ' + $scope.appointmentNote + '</p><p class="green_clr invoice_paidd" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.invoicePaid + '</p><p class="Invoice_outstanding" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.outstandingInvoice + '</p></div>'+
                    '<div class="tooltip_btns"><button class="p_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.arrivedBtn + '</button> <button class="red_btn p_not_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.notArrivedBtn + '</button> <button class="red_btn p_absent" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.absentBtn + '</button> <button class="a_completed" ng-if="'+data.appnt_status+'"><i class="fa fa-check"></i> ' + $scope.CompletedBtn + '</button> <button class="gray_btn a_not_completed" ng-if="'+data.appnt_status+'"> ' + $scope.notCompleteBtn + '</button><button class="red_btn a_pending" ng-if="'+data.appnt_status+'"> ' + $scope.pendingBtn + '</button></div>';
            }
            if((data.associated_treatment_note_status != null && data.associated_treatment_note_status == false)) {
                var content =  attach_img +
                    '<h4>' + data.title + '</h4>' +
                    '<h3>With ' + docter + '</h3>' +
                    '<p class="start_date">' + startDate + '<br />' +
                    '<p class="start_time">' + startTime + ' To ' + endTime +' ('+data.total_duration+')'+ '</p>' +
                    '<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + appointment_type_name + '</h6>' +
                    '<div class="notes_indications"><span><p class="red_clr"><i class="fa fa-file-text-o"></i> ' + $scope.treatmentNoteDraft + '</p></span>' +'<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + 'Reference# '+data.reference_number + '</h6>' +
                    '<div class="notes_indications">'+
                    '<p class="green_clr is_notes_avail"  ng-if="'+data.is_notes_avail+'"><i class="fa fa-calendar"></i> ' + $scope.appointmentNote + '</p><p class="green_clr invoice_paidd" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.invoicePaid + '</p><p class="Invoice_outstanding" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.outstandingInvoice + '</p></div>'+
                    '<div class="tooltip_btns"><button class="p_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.arrivedBtn + '</button> <button class="red_btn p_not_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.notArrivedBtn + '</button> <button class="red_btn p_absent" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.absentBtn + '</button> <button class="a_completed" ng-if="'+data.appnt_status+'"><i class="fa fa-check"></i> ' + $scope.CompletedBtn + '</button> <button class="gray_btn a_not_completed" ng-if="'+data.appnt_status+'"> ' + $scope.notCompleteBtn + '</button><button class="red_btn a_pending" ng-if="'+data.appnt_status+'"> ' + $scope.pendingBtn + '</button></div>';
            }
            if(data.associated_treatment_note_status == null) {
                var content =  attach_img +
                    '<h4>' + data.title + '</h4>' +
                    '<h3>With ' + docter + '</h3>' +
                    '<p class="start_date">' + startDate + '<br />' +
                    '<p class="start_time">' + startTime + ' To ' + endTime +' ('+data.total_duration+')'+ '</p>' +
                    '<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + appointment_type_name + '</h6>' +
                    '<div class="notes_indications">'+'<h6 style="color:' + color + '"><span style="background:' + color + '"></span>' + 'Reference# '+data.reference_number + '</h6>' +
                    '<div class="notes_indications">'+
                    '<p class="green_clr is_notes_avail"  ng-if="'+data.is_notes_avail+'"><i class="fa fa-calendar"></i> ' + $scope.appointmentNote + '</p><p class="green_clr invoice_paidd" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.invoicePaid + '</p><p class="Invoice_outstanding" ng-if="'+data.associated_invoice_status+'"><i class="fa fa-file-archive-o"></i> ' + $scope.outstandingInvoice + '</p></div>'+
                    '<div class="tooltip_btns"><button class="p_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.arrivedBtn + '</button> <button class="red_btn p_not_arrived" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.notArrivedBtn + '</button> <button class="red_btn p_absent" ng-if="'+data.patient_arrive+'"><i class="fa fa-user"></i> ' + $scope.absentBtn + '</button> <button class="a_completed" ng-if="'+data.appnt_status+'"><i class="fa fa-check"></i> ' + $scope.CompletedBtn + '</button> <button class="gray_btn a_not_completed" ng-if="'+data.appnt_status+'"> ' + $scope.notCompleteBtn + '</button><button class="red_btn a_pending" ng-if="'+data.appnt_status+'"> ' + $scope.pendingBtn + '</button></div>';
            }

            tooltip.set({
                'content.text': content,
            }).reposition(event).show(event);
        };

        // to hide the tooltip
        $scope.eventMouseout = function () {
            tooltip.hide();
            clearTimeout(t);
        };

        /* remove event */
        $scope.remove = function (index) {
            $scope.events.splice(index, 1);
        };

        /* Change View */
        $scope.renderCalender = function (calendar) {
            $timeout(function () {
                if (uiCalendarConfig.calendars[calendar]) {
                    uiCalendarConfig.calendars[calendar].fullCalendar('render');
                }
            });
        };

        /* Render Tooltip */
        $rootScope.bounce=false;
        $rootScope.bounceId;
        $scope.eventRender = function (event, element, view) {
            var icons = '';
            if(event.online_booked){
              icons += "<img src='/assets/cloud-icon.png' width='15' height='15'>"
            }
            if(event.is_cancel){
                icons += "<img src='/assets/cancelApp.png' width='14' height='14' >"; 
            }
            if(event.patient_arrive && !event.is_cancel){
                icons += "<img src='/assets/user-icon.png' width='14' height='14' class='right_most"+event.appnt_status+"'>"
            }
            else if (event.patient_arrive == false && !event.is_cancel) {
                icons += "<img src='/assets/disable_app.png' width='14' height='14' class='right_most"+event.appnt_status+"'>"
            }
            if (event.appnt_status && !event.is_cancel) {
                icons += "<img src='/assets/check-icon.png' width='17' height='16'>"
            }
            else if (event.appnt_status == false && !event.is_cancel) {
                icons += "<img src='/assets/pending-icon.png' width='15' height='15'>"
            }
            
            element.find("div.fc-content").prepend("<div class='appointment-icons'>"+icons+"</div>");

            getDataFromPatientCtlr();

            if($rootScope.bounce && event.id==$rootScope.bounceId){
                setTimeout(function () {
                    angular.element(document.getElementsByClassName(''+event.id)).addClass("animated bounce");
                }, 1000);
                setTimeout(function () {
                    angular.element(document.getElementsByClassName(''+event.id)).removeClass("animated bounce");
                    bounce=false;
                    $rootScope.bounceId=null;
                }, 2000);}
        };

        /*day click */
        var daycheck = '';

        $scope.closeReschedule=function(){
            $rootScope.reSchedule=false;
            $rootScope.reScheduleUnavail=false;
            $rootScope.reScheduleData=null;
        };
        $scope.closeAnother=function(){
            $rootScope.anotherApp=false;
            $rootScope.anotherAppData=null;
            $rootScope.unavailableActivate=false;
            $rootScope.availableActivate=false;
        };
        var escAction=angular.element('body');
        escAction.keyup(function(e) {
            if (e.which == 27){
                $rootScope.reScheduleData=null;
                $rootScope.anotherApp=false;
                $rootScope.anotherAppData=null;
                $rootScope.unavailableActivate=false;
                $rootScope.availableActivate=false;
                $rootScope.reSchedule=false;
                $rootScope.reScheduleUnavail=false;
                $rootScope.getEvents();
            }
        });

        // On click on any day to add appointment
        $scope.dayclick = function (event, jsEvent, view, resourceObj) {
            if (resourceObj != undefined) {
                UserSettings[currentUser].currentResource = resourceObj.id;
                localStorage.UserSettings = JSON.stringify(UserSettings);
            }
            if($rootScope.unavailableActivate==true || $rootScope.availableActivate==true){
                // to add un-available block
                var modalInstance = $uibModal.open({
                    templateUrl: 'unavailBlock.html',
                    controller: 'unavailBlockCtrl',
                    size: 'large_modal waitList_modal',
                    windowClass: "modal in",
                    resolve: {
                        event: function () {
                            return event;
                        }
                    }
                });
            }
            else{
                if ($rootScope.appPerm.create) {
                    if($rootScope.reScheduleData!=null){
                        //If appointment getting resceduled
                        $scope.eventData = event;
                        var newStartHour = event._d.getUTCHours();
                        var newStartMin = event._d.getUTCMinutes();
                        var newStartTime = event._d;
                        var getstartHr = event._d.getUTCHours();
                        var getstartMin = event._d.getUTCMinutes();
                        var mergeDate=getstartHr+':'+getstartMin;
                        var selectedDate=Date.parse('1-1-2000 ' + mergeDate);
                        var newStartDate= new Date(selectedDate);
                        var newEndDate = new Date(newStartDate.getTime() + $rootScope.reScheduleData.appnt_duration_min * 60000);
                        var newEndHour = newEndDate.getHours();
                        var newEndMin = newEndDate.getMinutes();
                        var resoureID;
                        if(resourceObj != undefined){
                            var resoureID = parseInt(resourceObj.id);
                        }
                        else{
                            var resoureID = $rootScope.reScheduleData.practitioner_id;
                        }
                        var appID = $rootScope.reScheduleData.id;
                        $rootScope.bounceId = appID;
                        var newDay = event._d.getUTCDate();
                        var newMonth = event._d.getUTCMonth() + 1;
                        var newYear = event._d.getUTCFullYear();

                        $scope.appointment = {};
                        if($rootScope.reScheduleUnavail==false){
                            var patientID = $rootScope.reScheduleData.patient_detail.patient_id;
                            $scope.appointment.patient_id = patientID;
                        }
                        $scope.appointment.id = appID;
                        $scope.appointment.user_id = resoureID;
                        if($rootScope.reScheduleUnavail==false){
                            $scope.appointment.appnt_date = newYear + '-' + newMonth + '-' + newDay;
                        }
                        else{
                            $scope.appointment.avail_date = newYear + '-' + newMonth + '-' + newDay;
                        }
                        $scope.appointment.start_hr = newStartHour;
                        $scope.appointment.start_min = newStartMin;
                        $scope.appointment.end_hr = newEndHour;
                        $scope.appointment.end_min = newEndMin;

                        if($rootScope.reScheduleUnavail==false){
                            $scope.appointment = {appointment: $scope.appointment};
                            $scope.confirmDrag = function () {
                                $rootScope.cloading = true;
                                $http.put('/appointments/' + appID +'/partial/update', $scope.appointment).success(function (data) {
                                    $rootScope.cloading = false;
                                    if (data.flag == true) {
                                        $rootScope.reScheduleData=null;
                                        $translate('toast.updateAppointment').then(function (msg) {
                                            $rootScope.showSimpleToast(msg);
                                        });
                                        $rootScope.getEvents();
                                        $rootScope.reSchedule=false;
                                        $rootScope.bounce=true;
                                        $rootScope.bounceId=appID
                                    }
                                    else {
                                        $rootScope.errors = data.error;
                                        $rootScope.showMultyErrorToast();
                                    }
                                });
                            };
                            $scope.confirmDrag();
                        }
                        else{
                            $scope.availability = {availability: $scope.appointment} ;
                            $scope.confirmDrag = function () {
                                $rootScope.cloading = true;
                                delete $scope.availability.availability.patient_id;
                                $http.put('/appointments/' + $scope.availability.availability.user_id +'/availability/'+appID+'/partial', $scope.availability).success(function (data) {
                                    $rootScope.cloading = false;
                                    if (data.flag == true) {
                                        $rootScope.reScheduleData=null;
                                        $translate('toast.updateUnavail').then(function (msg) {
                                            $rootScope.showSimpleToast(msg);
                                        });
                                        $rootScope.getEvents();
                                        $rootScope.reScheduleUnavail=false;
                                        $rootScope.bounce=true;
                                        $rootScope.bounceId=$scope.availability.availability.user_id;
                                    }
                                    else {
                                        $modalInstance.dismiss('cancel');
                                        $rootScope.errors = data.error;
                                        $rootScope.showMultyErrorToast();
                                    }
                                });
                            };
                            $scope.confirmDrag();
                        }
                    }
                    else{
                        // to add new appointment
                        var modalInstance = $uibModal.open({
                            templateUrl: 'newAppointment.html',
                            controller: 'newAppointmentCtrl',
                            windowClass: "modal in",
                            size: 'large_modal',
                            resolve: {
                                event: function () {
                                    return event;
                                }
                            }
                        });
                    }
                }
                else{
                    $rootScope.showErrorToast('Sorry you dont have permission to create appointment')
                }
            }
        };

        function getDataFromPatientCtlr(){
            if($state.params.appointment_date && $state.params.appointment_id){
                console.log('Here the calling....');
                uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate',$state.params.appointment_date);
                $rootScope.bounce=true;
                $rootScope.bounceId=$state.params.appointment_id;
            }
        }

        $scope.activateButtons=function(){
            var myE3 = angular.element( document.querySelectorAll( '.dates_con .btn-sm' ));
            if($scope.dt=="2016-05-05"){
                myE3.addClass('noSpace');
            }
        }

        if (localStorage.getItem('newPatientId')) {
            $rootScope.anotherApp=true;
            $rootScope.anotherAppData = {};
            $rootScope.anotherAppData.patient_detail = {};
            $rootScope.anotherAppData.patient_detail.patient_id = parseInt(localStorage.getItem('newPatientId'));
            $rootScope.anotherAppData.patient_detail.patient_name = localStorage.getItem('newPatientName');
            localStorage.removeItem('newPatientId');
            localStorage.removeItem('newPatientName');
        }

        $scope.vDestroy = function (view) {
            $scope.scroll = -1;
            if(view.name=='agendaSevenDay' || view.name=='agendaSixDay' || view.name=='agendaFiveDay' || view.name=='agendaOneDay' || view.name=='agendaThreeDay') {
                $scope.scroll = document.querySelector('.fc-scroller').scrollTop;
                if ($scope.scroll > 0){
                    localStorage.setItem("scrollHeight", $scope.scroll);
                }
            }
        }
        /* config object */
        $scope.vrender = function (view, element) {
            var height = localStorage.getItem('scrollHeight');
            $scope.getCurrentView=view;
            $scope.activateButtons();
            $scope.getCalendarSettings();
            UserSettings[currentUser].savedview = view.name
            localStorage.UserSettings = JSON.stringify(UserSettings);

            //localStorage.setItem('savedview', view.name);
            $scope.saveView = UserSettings[currentUser].savedview;
            /*if (view.name == 'agendaOneDay') {
             tooltip.position.my.x = 'left';
             tooltip.position.at.x = 'right';
             tooltip.prerender = false;
             angular.element('.qtip-light').addClass('dayOne');
             }
             else{
             tooltip.position.my.x = 'right';
             tooltip.position.at.x = 'left';
             tooltip.prerender = true;
             angular.element('.qtip-light').removeClass('dayOne');
             }*/
            if(height > -1 && (view.name=='agendaSevenDay' || view.name=='agendaSixDay' || view.name=='agendaFiveDay' || view.name=='agendaOneDay' || view.name=='agendaThreeDay')) {
               setTimeout(function(){
                    document.querySelector('.fc-scroller').scrollTop = height;
                },500);
            }

            if (view.name == 'agendaOneDay' || view.name == 'agendaThreeDay') {
                $rootScope.singlePrac = false;
            }
            else {
                $rootScope.singlePrac = true;
            }
            if ($scope.PractitionerCheckbox == true) {
                if (view.name == 'agendaOneDay' || view.name == 'agendaThreeDay') {
                    $scope.PractitionerCheckbox = true;
                    $scope.PractitionerRadio = false;
                }
                else {
                    $scope.PractitionerCheckbox = false;
                    $scope.PractitionerRadio = true;
                }
            }
            else {
                if (view.name == 'agendaOneDay' || view.name == 'agendaThreeDay') {
                    $scope.PractitionerCheckbox = true;
                    $scope.PractitionerRadio = false;
                }
                else {
                    $scope.PractitionerCheckbox = false;
                    $scope.PractitionerRadio = true;
                }
            }

            $scope.praTabbing = function () {
                if (view.name == 'agendaOneDay' || view.name == 'agendaThreeDay') {
                    $scope.PractitionerCheckbox = true;
                    $scope.PractitionerRadio = false;
                }
                else {
                    $scope.PractitionerCheckbox = false;
                    $scope.PractitionerRadio = true;
                }
                /*For active class*/
                $scope.addActiveCalender = false;
                $scope.addActivePra = true;
                $scope.addActiveWait = false;
                $scope.addActiveFilter = false;
                $scope.filterCheckbox = false;
                $scope.waitList = false;
                $scope.calenderOpen = false;
                localStorage.setItem('sideBarState', 'practi');
            };

            $scope.openPractitioner = function () {
                if (view.name == 'agendaOneDay' || view.name == 'agendaThreeDay') {
                    $scope.PractitionerCheckbox = true;
                    $scope.PractitionerRadio = false;
                }
                else {
                    $scope.PractitionerCheckbox = false;
                    $scope.PractitionerRadio = true;
                }
                $scope.openMenu = true;
                $scope.beforeExpand = false;
                $scope.openedMenu = true;
                $scope.showClose = true;
                /*For active class*/
                $scope.addActiveCalender = false;
                $scope.addActivePra = true;
                $scope.addActiveWait = false;
                $scope.addActiveFilter = false;
                $scope.filterCheckbox = false;
                $scope.waitList = false;
                $scope.calenderOpen = false;
                localStorage.setItem('sideBarState', 'practi');
            };
            if($scope.calenderOpen==true || $scope.waitList==true || $scope.filterCheckbox==true){
                $scope.PractitionerCheckbox = false;
                $scope.PractitionerRadio = false;
            }
            $rootScope.getEvents(view);
            //$scope.disableTodayButton();
            $timeout(function () { $scope.disableTodayButton(); }, 100);
        };

        $scope.disableTodayButton = function(){
            if(uiCalendarConfig.calendars['myCalendar3']!=undefined){
                var disableToday = angular.element( document.querySelectorAll( '.fc-todayButton-button' ));
                var curDate = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getDate')._d
                var todayDate = new Date();
                if(curDate.getDate() == todayDate.getDate() && curDate.getMonth() == todayDate.getMonth() && curDate.getFullYear() == todayDate.getFullYear()){
                    disableToday.addClass('fc-disabled');
                }
                else{
                    disableToday.removeClass('fc-disabled');
                }
            }
        }

        // skip weeks
        $scope.gotoNextweek = function (Incday) {
            $scope.skip = true;
            $scope.currentMonth = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getDate')._d
            date = $scope.currentMonth;
            var nextd = date.setDate($scope.currentMonth.getDate() + Incday);
            $scope.currentMonth = new Date(nextd);

            var newNexToNext = date.setMonth($scope.currentMonth.getMonth() + 1);
            var newNextDate = new Date(newNexToNext);
            $scope.nextMonth = new Date(newNextDate);

            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate', new Date(nextd));
            if ($scope.skip == true) {
                $scope.PractitionerRadio = false;
                $scope.PractitionerCheckbox = false;
            }
            $scope.skip = false;
        };

        // skip months
        $scope.gotoNextmonth = function (Incm) {
            $scope.currentMonth = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getDate')._d
            $scope.skip = true;
            date = $scope.currentMonth;
            var nextm = date.setMonth($scope.currentMonth.getMonth() + Incm);
            $scope.currentMonth = new Date(nextm);

            var newNexToNext = date.setMonth($scope.currentMonth.getMonth() + 1);
            var newNextDate = new Date(newNexToNext);
            $scope.nextMonth = new Date(newNextDate);

            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate', new Date(nextm));
            if ($scope.skip == true) {
                $scope.PractitionerRadio = false;
                $scope.PractitionerCheckbox = false;
            }
            $scope.skip = false;
        };
        $scope.calendarMin = '6:00:00';
        $scope.calendarMax = '22:00:00';
        $scope.slotSize = '00:15:00';

        // To get updates from setting module
        $scope.getCalendarSettings = function () {
            $rootScope.cloading = true;
            Data.get('/appointments/calendar/settings').then(function (results) {
                if (results.code) {
                    $state.go('dashboard');
                    $rootScope.showErrorToast(results.error);
                }
                else{
                    $scope.calendarSettings = results;
                    $scope.cell_height=parseInt(results.height);
                    $scope.uiConfig.calendar.minTime = $scope.calendarSettings.time_range.min_time + ':' + $scope.calendarSettings.time_range.min_minute + ':00';
                    $scope.uiConfig.calendar.maxTime = $scope.calendarSettings.time_range.max_time + ':' + $scope.calendarSettings.time_range.max_minute + ':00';
                    //current time indication
                    $scope.uiConfig.calendar.views.agendaThreeDay.nowIndicator=$scope.calendarSettings.show_time_indicator;
                    $scope.uiConfig.calendar.views.agendaSixDay.nowIndicator=$scope.calendarSettings.show_time_indicator;
                    $scope.uiConfig.calendar.views.agendaOneDay.nowIndicator=$scope.calendarSettings.show_time_indicator;
                    $scope.uiConfig.calendar.views.agendaSevenDay.nowIndicator=$scope.calendarSettings.show_time_indicator;
                    $scope.uiConfig.calendar.views.agendaFiveDay.nowIndicator=$scope.calendarSettings.show_time_indicator;
                    $scope.eventSpacing($scope.calendarSettings.multi_appointment);

                    $scope.uiConfig.calendar.windowResizeDelay = 1200;


                    angular.element('.fc-slats table tr').height($scope.cell_height);
                    // $('#calendar').fullCalendar({contentHeight: 800});
                    // $('#calendar').fullCalendar({height:800});
                    $scope.uiConfig.calendar.slotDuration = '00:' + $scope.calendarSettings.size + ':00';
                    $rootScope.cloading = false;
                    localStorage.setItem('savedMinTime', $scope.calendarSettings.time_range.min_time + ':00:00');
                    localStorage.setItem('savedMaxTime', $scope.calendarSettings.time_range.max_time + ':00:00');
                }
            });
        };

        // To Increase or decrease space between margin and appointment
        $scope.eventSpacing=function(isSpace){
            var myEl = angular.element( document.querySelectorAll( '.fc-event-container' ));
            if (isSpace) {
                myEl.removeClass('noSpace');
            }
            else{
                myEl.addClass('noSpace');
            }
        }
        $translate(['calendar.agendaDay1', 'calendar.WorkWeek', 'calendar.agendaDay3', 'calendar.agendaDay6', 'calendar.WholeWeek', 'calendar.todayBtn', 'calendar.day1', 'calendar.day2', 'calendar.day3', 'calendar.day4', 'calendar.day5', 'calendar.day6', 'calendar.day7', 'calendar.month1', 'calendar.month2', 'calendar.month3', 'calendar.month4', 'calendar.month5', 'calendar.month6', 'calendar.month7', 'calendar.month8', 'calendar.month9', 'calendar.month10', 'calendar.month11', 'calendar.month12']).then(function (translations) {
            $scope.dayOne = translations['calendar.agendaDay1'];
            $scope.workWeek = translations['calendar.WorkWeek'];
            $scope.dayThree = translations['calendar.agendaDay3'];
            $scope.daysix = translations['calendar.agendaDay6'];
            $scope.wholeWeek = translations['calendar.WholeWeek'];
            $scope.todayBtn = translations['calendar.todayBtn'];
            $scope.uiConfig.calendar.views.agendaOneDay.buttonText = $scope.dayOne;
            $scope.uiConfig.calendar.views.agendaThreeDay.buttonText = $scope.dayThree;
            $scope.uiConfig.calendar.views.agendaFiveDay.buttonText = $scope.workWeek;
            $scope.uiConfig.calendar.views.agendaSixDay.buttonText = $scope.daysix;
            $scope.uiConfig.calendar.views.agendaSevenDay.buttonText = $scope.wholeWeek;
            $scope.uiConfig.calendar.buttonText.today = $scope.todayBtn;
            $scope.uiConfig.calendar.dayNamesShort = [translations['calendar.day1'], translations['calendar.day2'], translations['calendar.day3'], translations['calendar.day4'], translations['calendar.day5'], translations['calendar.day6'], translations['calendar.day7']];
            $scope.uiConfig.calendar.monthNamesShort = [translations['calendar.month1'], translations['calendar.month2'], translations['calendar.month3'], translations['calendar.month4'], translations['calendar.month5'], translations['calendar.month6'], translations['calendar.month7'], translations['calendar.month8'], translations['calendar.month9'], translations['calendar.month10'], translations['calendar.month11'], translations['calendar.month12']];
        });

        //set view
        if (UserSettings[currentUser].savedview == undefined) {
            UserSettings[currentUser].savedview = 'agendaFiveDay';
            localStorage.UserSettings = JSON.stringify(UserSettings);
            //localStorage.setItem('savedview', 'agendaFiveDay');
        }
        $scope.saveView = UserSettings[currentUser].savedview;

        //full calendar config
        $scope.uiConfig = {
            calendar: {
                editable: true,
                eventStartEditable: true,
                eventDurationEditable: true,
                lazyFetching: true,
                eventLimit: true,
                allDay: false,
                selectable: false,
                forceEventDuration: true,
                defaultTimedEventDuration: '00:15:00',
                allDaySlot: false,
                selectHelper: true,
                unselectAuto: true,
                defaultEventMinutes: 120,
                defaultView: $scope.saveView,
                contentHeight:766,
                defaultDate: '12/3/2016',
                eventOverlap: true,
                nowIndicator: true,
                slotEventOverlap: false,
                minTime: $scope.calendarMin,
                maxTime: $scope.calendarMax,
                buttonText:{},
                dayNamesShort:[],
                monthNamesShort: [],
                theme : false,
                columnFormat: "ddd D MMM",
                customButtons: {
                    todayButton: {
                        text: 'Today',
                        click: function() {
                            var date  = new Date();
                            $scope.currentMonth = new Date();
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('today');
                            var newNexToNext = date.setMonth($scope.currentMonth.getMonth() + 1);
                            var newNextDate = new Date(newNexToNext);
                            $scope.nextMonth = newNextDate;
                        }
                    },
                    nextButton: {
                        icon : 'right-single-arrow',
                        click: function() {
                            $scope.currentMonth = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getDate')._d
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('next');
                            var newNexToNext = date.setMonth($scope.currentMonth.getMonth() + 1);
                            var newNextDate = new Date(newNexToNext);
                            $scope.nextMonth = new Date(newNextDate);
                        }
                    },
                    preButton: {
                        icon : 'left-single-arrow',
                        click: function() {
                            $scope.currentMonth = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getDate')._d
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('prev');
                            var newNexToNext = date.setMonth($scope.currentMonth.getMonth() + 1);
                            var newNextDate = new Date(newNexToNext);
                            $scope.nextMonth = new Date(newNextDate);
                        }
                    }
                },
                header: {
                    left: '',
                    center: 'preButton , title , nextButton',
                    right: 'todayButton,agendaOneDay,agendaThreeDay,agendaFiveDay,agendaSixDay,agendaSevenDay'
                },
                views: {
                    agendaThreeDay: {
                        type: 'agenda',
                        duration: {
                            days: 3
                        },
                        buttonText: '3 days',
                        groupByDateAndResource: true
                    },
                    agendaSixDay: {
                        type: 'agenda',
                        duration: {
                            days: 7
                        },
                        hiddenDays: [0],
                    },
                    agendaOneDay: {
                        type: 'agenda',
                        duration: {
                            days: 1
                        },
                        groupByDateAndResource: true
                    },
                    agendaSevenDay: {
                        type: 'agenda',
                        duration: {
                            days: 7
                        },
                        buttonText: 'Whole week'
                    },
                    agendaFiveDay: {
                        type: 'agenda',
                        hiddenDays: [0,6],
                        duration: {
                            days: 7
                        },
                    }
                },
                theme: false,
                editable: true,
                slotDuration: $scope.slotSize,
                eventClick: $scope.firstAppoinment,
                eventDrop: $scope.alertOnDrop,
                eventResize: $scope.alertOnDrop,
                eventRender: $scope.eventRender,
                dayClick: $scope.dayclick,
                eventMouseover: $scope.eventMouseover1,
                eventMouseout: $scope.eventMouseout,
                viewDestroy : $scope.vDestroy,
                viewRender: $scope.vrender
            },
        };

        /* event sources array*/
        $scope.eventSources2 = [
            $scope.eventsF,
            $scope.events,
        ];

        $scope.today = function () {
            var currentMonth = new Date();
            $scope.currentMonth = new Date();
            $scope.uiConfig.calendar.defaultDate = $scope.currentMonth;
            var nextmonth = date.setMonth((currentMonth).getMonth()+1);
            $scope.nextMonth=new Date(nextmonth);
        };
        $scope.today();

        //calendar navigation
        $scope.currentMonth=new Date();
        $scope.currentDate = new Date();
        $scope.nextCal=function(data){
            var year = data.getFullYear(),
                month = data.getMonth() + 2,
                date = data.getDate();
            var nextMonth = data.setFullYear(year, month, 1);

            $scope.currentMonth=new Date(nextMonth);
            $scope.currentDate = $scope.currentMonth;

            var yearNext = $scope.currentDate.getFullYear(),
                monthNext = $scope.currentDate.getMonth() + 1,
                dateNext = $scope.currentDate.getDate();
            var nextToMonth = $scope.nextMonth.setFullYear(yearNext, monthNext, 1);
            $scope.nextMonth=new Date(nextToMonth);
        };

        $scope.preCal=function(data){
            var year = data.getFullYear(),
                month = data.getMonth() - 2,
                date = data.getDate();
            var nextMonth = data.setFullYear(year, month, 1);

            $scope.currentMonth=new Date(nextMonth);
            $scope.currentDate = $scope.currentMonth;

            var yearNext = $scope.currentDate.getFullYear(),
                monthNext = $scope.currentDate.getMonth() + 1,
                dateNext = $scope.currentDate.getDate();
            var nextToMonth = $scope.nextMonth.setFullYear(yearNext, monthNext, 1);
            $scope.nextMonth=new Date(nextToMonth);
        };
        $scope.inlineOptions =
        {
            startingDay: 1,
            dateDisabled: disabled,
            minDate: new Date(),
            showWeeks: false
        };
        $scope.dateOptions =
        {
            dateDisabled: disabled,
            formatYear: 'yy',
            maxDate: new Date(2020, 5, 22),
            minDate: new Date(),
            startingDay: 1,
            showWeeks: false
        };

        // Disable weekend selection
        function disabled(data)
        {
            var date = data.date,
                mode = data.mode;
            return mode === 'day' && (date.getDay() === 0 || date.getDay() === 6);
        }

        $scope.toggleMin = function ()
        {
            $scope.inlineOptions.minDate = $scope.inlineOptions.minDate ? null : new Date();
            $scope.dateOptions.minDate = $scope.inlineOptions.minDate;
        };
        $scope.toggleMin();

        $scope.updateWeek = function (date)
        {
            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate', date);
            $scope.currentMonth = new Date(date);
        };

        $scope.setDate = function (year, month, day)
        {
            $scope.currentMonth = new Date(year, month, day);
            $scope.uiConfig.calendar.incrementDate = $scope.currentMonth;
        };

        $scope.updateWeekNext = function (date)
        {
            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('gotoDate', date);
        };

        var tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        var afterTomorrow = new Date();
        afterTomorrow.setDate(tomorrow.getDate() + 1);
        $scope.events = [
            {
                date: tomorrow,
                status: 'full'
            },
            {
                date: afterTomorrow,
                status: 'partially'
            }
        ];

        /*privacy on off buttons*/
        $scope.privacy_off = true;
        $scope.privacy_on = false;
        $scope.privacy_On = function () {
            $scope.privacy_off = false;
            $scope.privacy_on = true;
        };
        $scope.privacy_Off = function () {
            $rootScope.cloading = false;
            $scope.privacy_off = true;
            $scope.privacy_on = false;
        };

        //Get Bussiness List
        function getBussiness() {
            $rootScope.cloading = true;
            Data.get('/list/businesses').then(function (results) {
                $rootScope.BussinessList = results;
                if (UserSettings[currentUser].savedBusiness == undefined) {
                    UserSettings[currentUser].savedBusiness=$rootScope.BussinessList[0].id;
                    UserSettings[currentUser].savedBusinessName=$rootScope.BussinessList[0].name;
                    localStorage.setItem('UserSettings', JSON.stringify(UserSettings))
                };
                $scope.storedBusiness = UserSettings[currentUser].savedBusiness;
                $scope.selectBusiness($scope.storedBusiness);
                $rootScope.cloading = false;
            });
        };
        getBussiness();

        //select business
        $rootScope.currentBusiness = {};
        $scope.changeBus = false;
        $scope.selectBusiness = function (id, flag) {
            $scope.checkPracRadio = false;
            if(flag == true){
                $scope.changeBus = true;
            }
            else{
                $scope.changeBus = false;
            }
            return $q(function (resolve, reject) {
                for (i = 0; i < $rootScope.BussinessList.length; i++) {
                    if ($rootScope.BussinessList[i].id == id) {
                        resolve('business_recieved');
                        $scope.businessName();
                        $scope.selected_business = $rootScope.BussinessList[i];
                        $rootScope.currentBusiness = $rootScope.BussinessList[i];
                    }
                }
                UserSettings[currentUser].savedBusiness = id;
                UserSettings[currentUser].savedBusinessName = $scope.selected_business.name;
                localStorage.setItem('UserSettings', JSON.stringify(UserSettings) );
                $scope.businessName();
                var pracRecived = $rootScope.getPractitionar($scope.selected_business.id);

                pracRecived.then(function (greeting) {
                    if($scope.checkPracRadio == false && $scope.changeBus == true){
                        UserSettings[currentUser].savedPractradio = $rootScope.practitionarList[0].id;
                        localStorage.UserSettings = JSON.stringify(UserSettings);
                        $scope.selectedDoc=$rootScope.practitionarList[0].id;
                    }
                    var hit = pushResources();
                    hit.then(function (greeting) {
                        $rootScope.getEvents();
                    });
                });
            });
        };

        $scope.businessName=function(){
            var businessName=UserSettings[currentUser].savedBusinessName;
            $scope.splitBusiness = new Array();
            $scope.splitBusiness = businessName.split('');
            $scope.busName=[];
            for (a in $scope.splitBusiness) {
                $scope.busName.push({name:$scope.splitBusiness[a]});
            }
        };

        if(UserSettings[currentUser].savedBusinessName !=undefined){
            $scope.businessName();
        }

        //get docters list
        function getAllDoctersList() {
            $http.get('/settings/doctors').success(function (data) {
                $scope.allDoctersList = data.practitioners;
            });
        };
        getAllDoctersList();

        //practitionar list
        $rootScope.getPractitionar = function(id) {
            return $q(function (resolve, reject) {
                $scope.checkPracRadio = false;
                $rootScope.cloading = true;
                Data.get('/appointments/' + id + '/practitioners').then(function (results) {
                    if (!results.code) {
                        $rootScope.practitionarList = results.available_practitioners;
                        results.available_practitioners.forEach(function(test){
                            if(test.id==parseInt(UserSettings[currentUser].savedPractradio)){
                                $scope.checkPracRadio = true;
                            }
                        });
                        $rootScope.cloading = false;
                        if($rootScope.practitionarList.length==0){
                            $scope.openMenu = true;
                            $scope.beforeExpand = false;
                            $scope.openedMenu = true;
                            $scope.showClose = true;
                        }
                        else{
                            /*For active class*/
                            $scope.addActiveCalender = true;
                            $scope.addActivePra = false;
                            $scope.addActiveWait = false;
                            $scope.addActiveFilter = false;
                            $scope.PractitionerRadio = false;
                            $scope.PractitionerCheckbox = false;
                            $scope.filterCheckbox = false;
                            $scope.waitList = false;
                            $scope.calenderOpen = true;
                            localStorage.setItem('sideBarState', 'calendar');
                        }
                        resolve('prac_recieved');

                        if(UserSettings[currentUser].allDoctors != undefined){
                            var StoredDr = UserSettings[currentUser].allDoctors;
                            StoredDr = StoredDr.split(',');
                        }
                        if (UserSettings[currentUser].savedPractradio == "" || UserSettings[currentUser].savedPractradio==undefined) {
                            $scope.selectedDoc=$rootScope.practitionarList[0].id;
                            UserSettings[currentUser].allDoctors = ''+$scope.selectedDoc;
                            UserSettings[currentUser].savedPractradio = $scope.selectedDoc;
                            localStorage.UserSettings = JSON.stringify(UserSettings);
                        }
                        else{
                            if(UserSettings[currentUser].allDoctors!=""){
                                StoredDr.forEach(function(dr){
                                    results.available_practitioners.forEach(function(practi){
                                        if(dr == practi.id){
                                            practi.ischecked = true ;
                                        }
                                    });
                                });
                            }
                        }
                        if ($rootScope.practitionarList.length == 0) {
                            $scope.noPrac = false;
                        }
                        else {
                            $scope.noPrac = true;
                            $rootScope.getAppointmentType($rootScope.practitionarList[0].id);
                        }
                    }
                });
            });
        };

        $scope.updateresources = function(){
            $rootScope.practitionarList.forEach(function (practi) {
                uiCalendarConfig.calendars['myCalendar3'].fullCalendar('removeResource', practi.id);
            });
            UserSettings[currentUser].allDoctors = '' + $rootScope.practitionarList[0].id;
            localStorage.UserSettings = JSON.stringify(UserSettings);
        }

        //add resources
        $scope.resources = [];
        var resoruce = [];
        $scope.putAllDocter = false;
        $scope.addResources = function () {
            var noSelected = 0;
            $rootScope.practitionarList.forEach(function (practi) {
                if (practi.ischecked) {
                    uiCalendarConfig.calendars['myCalendar3'].fullCalendar('addResource', {
                        id: practi.id,
                        title: practi.first_name,
                    });
                }
                else {
                    $scope.putAllDocter = false;
                    noSelected += 1;
                    if (noSelected != $rootScope.practitionarList.length) {
                        uiCalendarConfig.calendars['myCalendar3'].fullCalendar('removeResource', practi.id);
                    }
                    else {
                        $scope.putAllDocter = true;
                        $rootScope.practitionarList.forEach(function (practi) {
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('addResource', {
                                id: practi.id,
                                title: practi.first_name,
                            });
                        });
                    }
                }
            });

            //add resources ID's into local storage
            var resources = uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getResources') ;
            var allDoctors = '';
            UserSettings[currentUser].allDoctors = allDoctors;
            localStorage.UserSettings = JSON.stringify(UserSettings);
            if ($scope.putAllDocter == false) {
                if (resources == '') {
                    allDoctors = '';
                    UserSettings[currentUser].allDoctors = allDoctors;
                    localStorage.UserSettings = JSON.stringify(UserSettings);
                }
                resources.forEach(function (rlist, i) {
                    if (i > 0 && i < resources.length) {
                        allDoctors += ',' ;
                    }
                    allDoctors += rlist.id;
                    UserSettings[currentUser].allDoctors = allDoctors;
                    localStorage.UserSettings = JSON.stringify(UserSettings);;
                });
                //$rootScope.getEvents();
            }
            $rootScope.getEvents();
        };

        //push resources from local storage
        var delayed;
        function pushResources() {
            return $q(function (resolve, reject) {
                if ($rootScope.practitionarList != undefined) {
                    var str = UserSettings[currentUser].allDoctors;
                    var rescid = new Array();
                    if (str == '') {
                        angular.forEach($rootScope.practitionarList, function (practi) {
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('addResource', {
                                id: practi.id,
                                title: practi.first_name,
                            });
                            rescid.push({id:practi.id,title:practi.first_name});
                        });
                    }
                    else {
                        var resourcesPush = new Array();
                        if(str){
                            resourcesPush = str.split(',');
                        }
                        for (a in resourcesPush) {
                            resourcesPush[a] = parseInt(resourcesPush[a]); // Explicitly include base as per Álvaro's comment
                        }

                        if ($scope.changeBus == true) {
                            for (j = 0; j < resourcesPush.length; j++) {
                                uiCalendarConfig.calendars['myCalendar3'].fullCalendar('removeResource', resourcesPush[j]);
                            }
                            UserSettings[currentUser].allDoctors = '' + $rootScope.practitionarList[0].id;
                            resourcesPush = [$rootScope.practitionarList[0].id]
                            localStorage.UserSettings = JSON.stringify(UserSettings);
                            $scope.changeBus = false;
                        }

                        for (k = 0; k < resourcesPush.length; k++) {
                            angular.forEach($rootScope.practitionarList, function (practi,i) {
                                if (resourcesPush[k] == practi.id) {
                                    rescid.push({id:practi.id,title:practi.first_name});
                                }

                                practi.ischecked = false;
                                uiCalendarConfig.calendars['myCalendar3'].fullCalendar('removeResource',practi.id);
                                $rootScope.practitionarList[i]= practi;
                            });
                        }
                        resolve('hit');
                        rescid.forEach(function(practi, i){
                            $rootScope.practitionarList[i].ischecked = true;
                            practi.ischecked = true;
                            uiCalendarConfig.calendars['myCalendar3'].fullCalendar('addResource', {
                                id: practi.id,
                                title: practi.title,
                            });
                        })
                    }
                    $scope.resources = rescid;
                    clearTimeout(delayed);
                }
                else {
                    delayed = setTimeout(function() {
                        pushResources()
                    });
                }
            });
        };
        pushResources();

        // to add resource ID in local storage
        $scope.addResourcesId = function (id) {
            UserSettings[currentUser].savedPractradio = id;
            localStorage.UserSettings= JSON.stringify(UserSettings)
            $rootScope.selectedDoc = UserSettings[currentUser].savedPractradio
            $rootScope.getAppointmentType(id);
            $rootScope.getEvents();
        };
        $scope.filter={};
        $scope.filter.patient_arrival=false;
        $scope.filter.patient_not_arrival=false;
        $scope.filter.invoice_paid=false;
        $scope.filter.outstanding_invoice=false;
        $scope.filter.tr_note_final=false;
        $scope.filter.tr_note_draft=false;
        $scope.filter.appnt_complete=false;
        $scope.filter.appnt_pending=false;
        $scope.filter.appnt_future=false;
        $scope.filter.no_appnt_future=false;

        $scope.filterAppointments=function(data){
            console.log('Data is here: ', data);
            var i = 0 ;
            angular.forEach(data, function(value, key) {
                if (value == true) {
                    i++;
                }
            });
            $rootScope.getEvents();
        };

        // to get events
        var delay;
        $rootScope.getEvents = function(view) {
            if (uiCalendarConfig.calendars['myCalendar3'] != undefined && $rootScope.currentBusiness.id) {
                var currentView = view ;
                if(view==undefined){
                    currentView= uiCalendarConfig.calendars['myCalendar3'].fullCalendar('getView');
                }
                $scope.currentView = currentView;
                var startDay = currentView.start._d.getUTCDate();
                var startMonth = currentView.start._d.getUTCMonth() + 1;
                var startYear = currentView.start._d.getUTCFullYear();
                var startDate = startDay + '/' + startMonth + '/' + startYear  ;
                if(currentView.end._d.getUTCDate()==1){
                    var endDay = currentView.end._d.getUTCDate();
                }
                else{
                    var endDay = currentView.end._d.getUTCDate() - 1;
                }
                var endMonth = currentView.end._d.getUTCMonth() + 1;
                var endYear = currentView.end._d.getUTCFullYear();
                var endDate = endDay + '/' + endMonth + '/' + endYear ;
                var doctors = '';
                if (currentView.name == 'agendaOneDay' || currentView.name == 'agendaThreeDay') {
                    if (UserSettings[currentUser].allDoctors!= "") {
                        doctors = UserSettings[currentUser].allDoctors
                    }
                }
                else {
                    $rootScope.selectedDoc = UserSettings[currentUser].savedPractradio
                    doctors = $rootScope.selectedDoc;
                }
                if(doctors==null){
                    $rootScope.selectedDoc=$rootScope.User_id;
                    doctors = $rootScope.selectedDoc;
                }
                $rootScope.cloading = true;
                appointmentServe.getEvents($rootScope.currentBusiness.id, doctors, startDate, endDate, $scope.filter.patient_arrival, $scope.filter.patient_not_arrival, $scope.filter.invoice_paid, $scope.filter.outstanding_invoice, $scope.filter.tr_note_final, $scope.filter.tr_note_draft, $scope.filter.appnt_complete, $scope.filter.appnt_pending, $scope.filter.appnt_future, $scope.filter.no_appnt_future, $scope.currentView)
                    .then(function(data) {
                        $scope.events =data;
                        $rootScope.cloading = false;
                        uiCalendarConfig.calendars['myCalendar3'].fullCalendar('refetchEvents');

                    });
                clearTimeout(delay);
            }
            else
            {
                delay = setTimeout(function() {
                    //$rootScope.getEvents();
                });
            }
        };

        function addCollon(value){
            var a = value.split('.') ;
            a = $scope.addZero(a[0])+':'+a[1];
            return a;
        }

        //Appointment Type list
        $rootScope.getAppointmentType = function(id, data) {
            $rootScope.cloading = true;
            return $q(function(resolve, reject) {
                setTimeout(function() {
                    Data.get('/appointments/' + id + '/appointment_types').then(function (results) {
                        $rootScope.appTypeList = results;
                        resolve('Hello');
                        $rootScope.appointmentTypeList = results.appointment_types;
                        if(data){
                            var filteredArray = filterFilter(results.appointment_types, {id:data.id});
                            if(filteredArray.length == 0){
                                results.appointment_types.push({id : data.id, category : data.category, color_code : data.color_code , duration_time : data.duration_time , name : data.name })
                            }
                        }
                        $rootScope.checkStatus = true;
                        $rootScope.cloading = false;
                        var cat = [];
                        results.appointment_types.forEach(function(at){
                            if(!hasobj(cat, at.category)){
                                cat.push({category:at.category,category_list:[at]})
                            }
                            else{
                                cat[getIndex(cat, at.category)].category_list.push(at)
                            }
                        })
                        function hasobj(array, val){
                            var a = false;
                            array.forEach(function(obj, i){
                                if(obj.category == val){
                                    a = true
                                }
                            })
                            return a;
                        }
                        function getIndex(array, val){
                            var a = false;
                            array.forEach(function(obj, i){
                                if(obj.category == val){
                                    a = i
                                }
                            })
                            return a;
                        }
                        var catO = cat.splice(0,1)
                        cat = cat.concat(catO)
                        $rootScope.appointmentTypes = cat;
                    });
                }, 1000);
            });
        };

        //Wait list
        $rootScope.getWaitList = function() {
            $rootScope.cloading = true;
            Data.get('/wait_lists').then(function(results) {
                $scope.wait_List = results.wait_lists;
                $rootScope.cloading = false;
            });
        } ;
        $rootScope.getWaitList();

        //filter waitlist
        $scope.filterDoc='all';
        $scope.filterBus='all';
        $scope.filterWaitlist=function(patient,docter,business){
            $rootScope.cloading = true;
            Data.get('/wait_lists?'+'patient='+patient+'&business='+business+'&doctor='+docter).then(function (results) {
                $scope.wait_List = results.wait_lists;
                $rootScope.cloading = false;
            });
        };

        // get practitionar list
        $rootScope.getPatientsData = function() {
            $http.get('/list/patients').success(function(data) {
                data.forEach(function(patient){
                    patient.fullName = patient.first_name+' '+patient.last_name;
                  })
                $rootScope.PatientListData = data;
                $rootScope.listLength = $scope.PatientListData.length;
                $rootScope.cloading = false;
            });
        };

        //check valid start time and end time
        $rootScope.checkValidation = function(data) {
            var startTime = data.start_hr + ':' + data.start_min;
            var endTime = data.end_hr + ':' + data.end_min;
            if (Date.parse('1-1-2000 ' + startTime) >= Date.parse('1-1-2000 ' + endTime)) {
                $rootScope.endTimeError = true ;
            }
            else {
                $rootScope.endTimeError = false;
            }
            $rootScope.checkAvailbility();
        };

        //check valid start time and end time
        $rootScope.checkValidationEdit = function(data) {
            var startTime = data.start_hr + ':' + data.start_min;
            var endTime = data.end_hr + ':' + data.end_min;
            if (Date.parse('1-1-2000 ' + startTime) >= Date.parse('1-1-2000 ' + endTime)) {
                $rootScope.endTimeError = true ;
            }
            else {
                $rootScope.endTimeError = false;
            }
            $rootScope.checkAvailbilityEdit();
        };

        //go on patient detail page
        $scope.goToPatientDetailPage=function(id, events){
            events.preventDefault();
            events.stopPropagation();
            $state.go('patient-detail', {'patient_id':id});
        };

        //go to print appointment list
        $rootScope.printAppointments = function(id){
            var win = window.open('/appointments/'+ id +'/future/booking.pdf', '_blank');
            win.focus();
        }
    }

]);

/*Confirmation Modal controler*/
app.controller('confirmationModalCtrl', [
    '$rootScope',
    '$scope',
    '$state',
    '$http',
    '$modal',
    '$uibModal',
    '$modalInstance',
    'event',
    '$translate',
    '$window' ,
    function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, event, $translate , $window) {
        /*close modal*/
        $scope.cancel = function () {
            $rootScope.getEvents();
            $modalInstance.dismiss('cancel');
        };
        $scope.eventData = event;
        var newStartHour = event.start._d.getUTCHours();
        var newEndHour = event.end._d.getUTCHours();
        var newStartMin = event.start._d.getUTCMinutes();
        var newEndMin = event.end._d.getUTCMinutes();
        var resoureID = event.resourceId;
        var patientID = event.Patient_Id;
        var appID = event.id;
        var newDay = event.start._d.getUTCDate();
        var newMonth = event.start._d.getUTCMonth() + 1;
        var newYear = event.start._d.getUTCFullYear();
        $scope.appointment = {};
        $scope.appointment.patient_id = patientID;
        $scope.appointment.id = appID;
        $scope.appointment.user_id = resoureID;
        if($scope.eventData.app_indication=="_un_app"){
            $scope.appointment.avail_date = newYear + '-' + newMonth + '-' + newDay;
        }
        else{
            $scope.appointment.appnt_date = newYear + '-' + newMonth + '-' + newDay;
        }
        $scope.appointment.start_hr = newStartHour;
        $scope.appointment.start_min = newStartMin;
        $scope.appointment.end_hr = newEndHour;
        $scope.appointment.end_min = newEndMin;

        if($scope.eventData.app_indication=="_un_app"){
            $scope.availability = {availability: $scope.appointment} ;
            $scope.confirmDrag = function() {
                $rootScope.cloading = true;
                delete $scope.availability.availability.patient_id;
                $http.put('/appointments/' + $scope.availability.availability.user_id +'/availability/'+appID+'/partial', $scope.availability).success(function (data) {
                    $rootScope.cloading = false;
                    if (data.flag == true) {
                        $modalInstance.dismiss('cancel');
                        $translate('toast.updateUnavail').then(function (msg) {
                            $rootScope.showSimpleToast(msg);
                        });
                        $rootScope.getEvents();
                    }
                    else {
                        $modalInstance.dismiss('cancel');
                        $rootScope.errors = data.error;
                        $rootScope.showMultyErrorToast();
                    }
                });
            };
        }
        else{
            $scope.appointment = {appointment: $scope.appointment};
            $scope.confirmDrag = function () {
                $rootScope.cloading = true;
                $http.put('/appointments/' + appID +'/partial/update', $scope.appointment).success(function (data) {
                    $rootScope.cloading = false;
                    if (data.flag == true) {
                        $modalInstance.dismiss('cancel');
                        $translate('toast.updateAppointment').then(function (msg) {
                            $rootScope.showSimpleToast(msg);
                        });
                        $rootScope.getEvents();
                    }
                    else {
                        $modalInstance.dismiss('cancel');
                        $rootScope.errors = data.error;
                        $rootScope.showMultyErrorToast();
                    }
                });
            } ;
        }
    }
]);

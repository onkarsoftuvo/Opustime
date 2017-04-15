angular.module('Zuluapp').config(function($provide){
$provide.decorator('taOptions', ['taRegisterTool', '$delegate','Data','$rootScope', function(taRegisterTool, taOptions,Data,$rootScope) { // $delegate is the taOptions we are decorating
                    taOptions.toolbar = [
                          ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'pre', 'quote','bold', 'italics', 'underline', 'strikeThrough', 'ul', 'ol', 'redo', 'undo', 'clear','justifyLeft', 'justifyCenter', 'justifyRight', 'indent', 'outdent'],
                          [],
                      ];
                    taRegisterTool('h_1', {
                        buttontext: 'Heading 1',
                        action: function() {
                          this.$editor().wrapSelection('formatBlock', '<h1>');
                        }
                    });
                    taRegisterTool('h_2', {
                        buttontext: 'Heading 2',
                        action: function() {
                          this.$editor().wrapSelection('formatBlock', '<h2>');
                        }
                    });
                    //Get Booking Info
                 var results;
                   Data.get('/settings/letter_template/tabs_info')
                    .then(function(results){
                        results=results;
                  });
                 
                    taRegisterTool('normal', {
                        buttontext: 'Normal',
                        action: function() {
                          this.$editor().wrapSelection('formatBlock', '<p>');
                        }
                    });
                    taRegisterTool('patient', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Patient</span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'Patient.FullName'}, {name: 'Patient.Title'}, {name: 'Patient.FirstName'}, {name: 'Patient.LastName'}, {name: 'Patient.MobileNumber'},
                      {name: 'Patient.HomeNumber'},{name: 'Patient.WorkNumber'},{name: 'Patient.FaxNumber'},{name: 'Patient.OtherNumber'},{name: 'Patient.Email'}
                      ,{name: 'Patient.Address'},{name: 'Patient.City'},{name: 'Patient.PostCode'},
                      {name: 'Patient.State'},{name: 'Patient.Country'},{name: 'Patient.DateOfBirth'},{name: 'Patient.Gender'},{name: 'Patient.Occupation'},
                      {name: 'Patient.EmergencyContact'},{name: 'Patient.ReferralSource'},{name: 'Patient.MedicareNumber'},{name: 'Patient.OldReferenceId'},{name: 'Patient.IdentificationNumber'},
                      {name: 'Patient.Notes'},{name: 'Patient.FirstAppointmentDate'},{name: 'Patient.FirstAppointmentTime'},{name: 'Patient.MostRecentAppointmentDate'},{name: 'Patient.MostRecentAppointmentTime'},
                      ,{name: 'Patient.NextAppointmentDate'},{name: 'Patient.NextAppointmentTime'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }

                      }
                    });
                    taRegisterTool('practitioner', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Practitioner</span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'Practitioner.FullName'}, {name: 'Practitioner.FullNameWithTitle'}, {name: 'Practitioner.Title'}, {name: 'Practitioner.FirstName'}, {name: 'Practitioner.LastName'}
                      , {name: 'Practitioner.Designation'}, {name: 'Practitioner.Email'}, {name: 'Practitioner.MobileNumber'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }

                      }
                    });
                    taRegisterTool('business', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Business</span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'Business.Name'}, {name: 'Business.FullAddress'}, {name: 'Business.Address'},{name: 'Business.City'},
                      {name: 'Business.State'},{name: 'Business.PostCode'},{name: 'Business.Country'},{name: 'Business.RegistrationName'},{name: 'Business.RegistrationValue'},{name: 'Business.WebsiteAddress'},
                      {name: 'Business.ContactInformation'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }

                      }
                    });
                    taRegisterTool('contact', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Contact</span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'Contact.FullName'}, {name: 'Contact.Title'}, {name: 'Contact.FirstName'}, {name: 'Contact.LastName'}, {name: 'Contact.PreferredName'}
                      , {name: 'Contact.CompanyName'}, {name: 'Contact.MobileNumber'}, {name: 'Contact.HomeNumber'}, {name: 'Contact.WorkNumber'}, {name: 'Contact.FaxNumber'}, {name: 'Contact.OtherNumber'}
                      , {name: 'Contact.Email'}, {name: 'Contact.Address'}, {name: 'Contact.City'}, {name: 'Contact.State'}
                      , {name: 'Contact.PostCode'}, {name: 'Contact.Country'}, {name: 'Contact.Occupation'}, {name: 'Contact.Notes'}, {name: 'Contact.ProviderNumber'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }

                      }
                    });
                    taRegisterTool('refDcotor', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Referring Doctor</span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'ReferringDoctor.FullName'}, {name: 'ReferringDoctor.Title'}, {name: 'ReferringDoctor.FirstName'}, {name: 'ReferringDoctor.LastName'}, {name: 'ReferringDoctor.PreferredName'}
                      ,{name: 'ReferringDoctor.CompanyName'},{name: 'ReferringDoctor.MobileNumber'},{name: 'ReferringDoctor.HomeNumber'},{name: 'ReferringDoctor.WorkNumber'},{name: 'ReferringDoctor.Faxnumber'},
                      {name: 'ReferringDoctor.OtherNumber'},{name: 'ReferringDoctor.Email'},{name: 'ReferringDoctor.Address'},
                      {name: 'ReferringDoctor.City'},{name: 'ReferringDoctor.State'},{name: 'ReferringDoctor.PostCode'},{name: 'ReferringDoctor.Country'},{name: 'ReferringDoctor.Occupation'},{name: 'ReferringDoctor.Notes'}
                      ,{name: 'ReferringDoctor.ProviderNumber'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }

                      }
                    });
                    taRegisterTool('general', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>General </span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'General.CurrentDate'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }
                      }
                    });
                    taRegisterTool('appointment', {
                      display: '<span class="custom-toolbar btn-group" dropdown style="padding: 0px 0px 0px 0px">' +
                      '<button class="btn btn-default dropdown-toggle " dropdown-toggle type="button" ng-disabled="showHtml()">' +
                      '   <span>Appointment </span>' +
                      '</button>' +
                      '<ul class="dropdown-menu">' +
                      '   <li ng-repeat="o in options">' +
                      '       <a ng-click="action(o)">{{o.name}}</a>' +
                      '   </li>' +
                      '</ul>' +
                      '</span>',
                      options:[ {name: 'Appointment.Date'},{name: 'Appointment.StartTime'},{name: 'Appointment.EndTime'},{name: 'Appointment.Type'},{name: 'Appointment.CancellationLink'}],
                      action: function (option) {
                          if(option.name != undefined){
                        this.$editor().wrapSelection('insertHTML', '<span>{{'+option.name+'}}</span>', true);
                        }
                      }
                    });
                    // add the button to the default toolbar definition
                    taOptions.toolbar[1].push('patient', 'practitioner', 'business', 'contact', 'refDcotor', 'general', 'h_1', 'h_2', 'normal', 'appointment' );
                    return taOptions;
  }]); });
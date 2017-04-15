
var opustime_app = angular.module('Zuluapp');
opustime_app.config(function ($stateProvider, $locationProvider, $urlRouterProvider, $ocLazyLoadProvider, $animateProvider, stateHelperProvider, ScrollBarsProvider, $httpProvider) {
  $animateProvider.classNameFilter(/angular-animate/);
  // $animateProvider.classNameFilter(/^(?:(?!no-animate).)*$/);
  ScrollBarsProvider.defaults = {
    scrollButtons: {
      scrollAmount: 'auto', // scroll amount when button pressed
      enable: true // enable scrolling buttons by default
    },
    scrollInertia: 400, // adjust however you want
    axis: 'yx',
    theme: 'dark',
    autoHideScrollbar: true,
    advanced: {
      updateOnContentResize: true
    }
  };
  // For any unmatched url, send to /route1
  $urlRouterProvider.otherwise('/dashboard');
  $locationProvider.hashPrefix('!');
  $stateProvider.state('login_first', {
     url: '/login_first',
     templateUrl: '/templates/common/login_first.html',
     data: {
         pageTitle: 'Login First',
         authRequire: false
     },
     controller: 'authFirstCtrl'
  })
  .state('login_second', {
     url: '/login_second',
     templateUrl: '/templates/common/login_second.html',
     data: {
         pageTitle: 'Login Second',
         authRequire: false
     },
     controller: 'authSecondCtrl'
  })
  .state('login', {
    url: '/login',
    templateUrl: '/templates/common/login.html',
    data: {
      pageTitle: 'Login',
      authRequire: false
    },
    controller: 'authCtrl'
  })
  .state('loginConfirm', {
    url: '/loginConfirm/:user_id',
    templateUrl: '/templates/common/login_confirm.html',
    data: {
      pageTitle: 'Login Confirm',
      authRequire: false
    },
    controller: 'loginConfirmCtrl',
    onExit: function ($state) {
      //console.log($state.current);
    }    /*resolve: {
                
                  loadModule: ['$ocLazyLoad', function ($ocLazyLoad) {
                      return $ocLazyLoad.load('assets/angular/controllers/common/SignUpCtrl.js');
                  }]
              }*/

  })
  .state('/password_resets/:id/edit', {
    url: '/password_resets/:id/edit',
    templateUrl: '/templates/common/reset-password.html',
    data: {
      pageTitle: 'Reset Password',
      authRequire: false
    },
    controller: 'resetPasswordCtrl',
    onExit: function ($state) {
    }
  })  //alide
  /*.state('alide', {
      url: "",
     templateUrl: '/templates/common/alide.html',
         data : { pageTitle: 'alide', authRequire: false},
            controller: 'alideCtrl',
            data : { pageTitle: 'alide', navlink: 'alide' }
    })*/
  .state('forgot_password', {
    url: '/forgot_password',
    templateUrl: '/templates/common/forgot-password.html',
    data: {
      pageTitle: 'ForgotPassword',
      authRequire: false
    },
    controller: 'forgotPasswordCtrl',
    onExit: function ($state) {
    }
  })
  .state('error', {
    url: '/error',
    templateUrl: '/templates/common/error.html'
  })
  .state('signup', {
    url: '/signup',
    templateUrl: '/templates/common/signup.html',
    data: {
      pageTitle: 'Signup',
      authRequire: false
    },
    controller: 'SignUpCtrl'    /*resolve: {
                
                  loadModule: ['$ocLazyLoad', function ($ocLazyLoad) {
                      return $ocLazyLoad.load('assets/angular/controllers/common/SignUpCtrl.js');
                  }]
              }*/
  })
  .state('signup/:comp_id', {
    url: '/signup/:comp_id',
    templateUrl: '/templates/common/signupInfo.html',
    data: {
      pageTitle: 'Signup Info',
      authRequire: false
    },
    controller: 'SignUpCtrl',
  })
  .state('termsandcondition', {
    url: '/termsandcondition/:comp_id',
    templateUrl: '/templates/common/termsAndCondition.html',
    data: {
      pageTitle: 'TermsAndCondition',
      authRequire: false
    },
    controller: 'TermsAndConditionCtrl',
  })
  .state('dashboard', {
    url: '/dashboard',
    templateUrl: '/templates/dashboard/dashboard.html',
    controller: 'dashboardCtrl',
    data: {
      pageTitle: 'Dashboard',
      authRequire: true
    } /*,
      resolve: {
                  loadModule: ['$ocLazyLoad', function ($ocLazyLoad) {
                      return $ocLazyLoad.load('assets/angular/controllers/dashboard/dashboardCtrl.js');
                  }]
              },*/

  })
  .state('settings', {
    url: '/settings',
    templateUrl: '/templates/settings/settings.html',
    controller: 'settingCtrl',
    data: {
      pageTitle: 'settings.top_links.account',
      navlink: 'Account',
      authRequire: true
    }
  })
  .state('settings.enateimport', {
    url: '/enateimport',
    templateUrl: '/templates/settings/enateimport.html',
    controller: 'enateimportCtrl',
    data: {
      pageTitle: 'Import',
      navlink: 'Data Export'
    }
  })
  .state('settings.account', {
    url: '/account/:comp_id',
    templateUrl: '/templates/settings/account-settings.html',
    controller: 'AccountsettingCtrl',
    data: {
      pageTitle: 'settings.top_links.account',
      navlink: 'Account'
    },
  })
  .state('settings.business', {
    url: '/business',
    templateUrl: '/templates/settings/select-business.html',
    controller: 'businessSettingCtrl',
    data: {
      pageTitle: 'settings.top_links.business_information',
      navlink: 'Business Information'
    }
  })
  .state('settings.business.info', {
    url: '/:business_id',
    templateUrl: '/templates/settings/business-information.html',
    controller: 'businessinfoCtrl',
    data: {
      pageTitle: 'settings.top_links.business_information',
      navlink: 'Business Information'
    }
  })
  .state('settings.business.new', {
    url: '/new/business',
    templateUrl: '/templates/settings/newBusiness.html',
    controller: 'businessNew',
    data: {
      pageTitle: 'settings.top_links.business_information',
      navlink: 'Business Information'
    }
  })
  .state('settings.users', {
    url: '/users',
    templateUrl: '/templates/settings/select-user.html',
    controller: 'UserSettingCtrl',
    data: {
      pageTitle: 'settings.top_links.users_practitioners',
      navlink: 'User & Practitioners'
    }
  })  
  /*.state('settings.users.info', {
    url: "/:user_id",
    templateUrl: "/templates/settings/users-practitioners.html",
    controller: 'UserSettingInfoCtrl',
        data : { pageTitle: 'settings.top_links.users_practitioners', navlink : 'Users & Practitioners'  }
  })*/
  .state('settings.users.info', {
    url: '/:user_id',
    templateUrl: '/templates/settings/CreateUser-practitioners.html',
    controller: 'UserSettingInfoCtrl',
    data: {
      pageTitle: 'settings.top_links.users_practitioners',
      navlink: 'Users & Practitioners'
    }
  })
  .state('settings.profile', {
    url: '/myProfile',
    templateUrl: '/templates/settings/profile.html',
    controller: 'UserSettingCtrl'
  })  
  .state('settings.userProfile', {
    url: '/user/:user_id',
    templateUrl: '/templates/settings/user_profile.html',
    controller: 'UserProfileCtrl',
    data: {
      pageTitle: 'settings.top_links.users_practitioners',
      navlink: 'Users & Practitioners'
    }
  }) 
  .state('settings.profile.myProfile', {
    url: '/:user_id',
    templateUrl: '/templates/settings/myProfile.html',
    controller: 'UserSettingInfoCtrl',
    data: {
      pageTitle: 'My Profile',
    }
  })
  .state('settings.users.new', {
    url: '/new/user',
    templateUrl: '/templates/settings/CreateUser-practitioners.html',
    controller: 'UserSettingNewCtrl',
    data: {
      pageTitle: 'settings.top_links.users_practitioners',
      navlink: 'Users & Practitioners'
    }
  })
  .state('settings.online-booking', {
    url: '/online-booking',
    templateUrl: '/templates/settings/online-booking.html',
    controller: 'onlineBookingCtrl',
    data: {
      pageTitle: 'settings.top_links.online_booking',
      navlink: 'Online Booking'
    }
  })
  .state('settings.discount-types', {
    url: '/discount-types',
    templateUrl: '/templates/settings/concession-types.html',
    controller: 'concessionTypesCtrl',
    data: {
      pageTitle: 'settings.top_links.discount_types',
      navlink: 'Discount Types'
    }
  })
  .state('settings.discount-types.edit', {
    url: '/:concession_id',
    templateUrl: '/templates/settings/concession-types-child.html',
    controller: 'concessionTypesChildCtrl',
    data: {
      pageTitle: 'settings.top_links.discount_types',
      navlink: 'Discount Types'
    }
  })
  .state('settings.taxes', {
    url: '/taxes',
    templateUrl: '/templates/settings/taxes.html',
    controller: 'taxsCtrl',
    data: {
      pageTitle: 'settings.top_links.taxes',
      navlink: 'Taxes'
    }
  })
  .state('settings.taxes.info', {
    url: '/:TaxID',
    templateUrl: '/templates/settings/taxes-info.html',
    controller: 'taxsCtrl',
    data: {
      pageTitle: 'settings.top_links.taxes',
      navlink: 'Taxes'
    }
  })
  .state('settings.referral-types', {
    url: '/referral-types',
    templateUrl: '/templates/settings/referral-types.html',
    controller: 'refferalTypeCtrl',
    data: {
      pageTitle: 'settings.top_links.referral_types',
      navlink: 'Referral Types'
    }
  })
  .state('settings.referral-types.edit', {
    url: '/:referalID',
    templateUrl: '/templates/settings/referral-types-form.html',
    controller: 'refferalTypeFormCtrl',
    data: {
      pageTitle: 'settings.top_links.referral_types',
      navlink: 'Referral Types'
    }
  })
  .state('settings.sms-setting', {
    url: '/sms-setting',
    templateUrl: '/templates/settings/sms-setting.html',
    controller: 'smsSettingCtrl',
    data: {
      pageTitle: 'settings.top_links.sms_setting',
      navlink: 'SMS Setting'
    }
  })
  .state('settings.recall-types', {
    url: '/recall-types',
    templateUrl: '/templates/settings/recall-types.html',
    controller: 'recallTypesCtrl',
    data: {
      pageTitle: 'settings.top_links.recall_types',
      navlink: 'Recall Types'
    }
  })
  .state('settings.recall-types.info', {
    url: '/:recallID',
    templateUrl: '/templates/settings/recall-types-info.html',
    controller: 'recallTypesCtrl',
    data: {
      pageTitle: 'settings.top_links.recall_types',
      navlink: 'Recall Types'
    }
  })
  .state('settings.invoice', {
    url: '/invoice',
    templateUrl: '/templates/settings/invoice_setting.html',
    controller: 'invoiceCtrl',
    data: {
      pageTitle: 'settings.top_links.invoice_setting',
      navlink: 'Invoice'
    }
  })
  .state('settings.payment-types', {
    url: '/payment-types',
    templateUrl: '/templates/settings/payment-types.html',
    controller: 'paymentTypeCtrl',
    data: {
      pageTitle: 'settings.top_links.payments_types',
      navlink: 'Payment Types'
    }
  })
  .state('settings.payment-types.info', {
    url: '/:paymentID',
    templateUrl: '/templates/settings/payment-types-info.html',
    controller: 'paymentTypeInfoCtrl',
    data: {
      pageTitle: 'settings.top_links.payments_types',
      navlink: 'Payment Types'
    }
  })
  .state('settings.subscription', {
    url: '/subscription',
    templateUrl: '/templates/settings/subscription.html',
    controller: 'subcsriptionCtrl',
    data: {
      pageTitle: 'settings.top_links.zulu_subscription',
      navlink: 'ZULU Subscription'
    }
  })
  .state('settings.treatment-notes', {
    url: '/treatment-notes',
    templateUrl: '/templates/settings/treatment-notes.html',
    controller: 'treatmentNoteCtrl',
    data: {
      pageTitle: 'settings.top_links.treatments_note_templates',
      navlink: 'Treatment Notes'
    }
  })
  .state('settings.treatment-notes.info', {
    url: '/:TnoteID/info',
    templateUrl: '/templates/settings/treatment-notes-info.html',
    controller: 'treatmentNoteInfoCtrl',
    data: {
      pageTitle: 'settings.top_links.treatments_note_templates',
      navlink: 'Treatment Notes'
    }
  })
  .state('settings.treatment-notes.edit', {
    url: '/:TnoteID/edit',
    templateUrl: '/templates/settings/treatment-notes-edit.html',
    controller: 'treatmentNoteEditCtrl',
    data: {
      pageTitle: 'settings.top_links.treatments_note_templates',
      navlink: 'Treatment Notes'
    }
  })
  .state('settings.treatment-notes.clone', {
    url: '/:TnoteID/:clone',
    templateUrl: '/templates/settings/treatment-notes-edit.html',
    controller: 'treatmentNoteNewCtrl',
    data: {
      pageTitle: 'settings.top_links.treatments_note_templates',
      navlink: 'Treatment Notes'
    }
  })
  .state('settings.treatment-notes.new', {
    url: '/new',
    templateUrl: '/templates/settings/treatment-notes-edit.html',
    controller: 'treatmentNoteNewCtrl',
    data: {
      pageTitle: 'settings.top_links.treatments_note_templates',
      navlink: 'Treatment Notes'
    }
  })
  .state('settings.appointment', {
    url: '/appointment',
    templateUrl: '/templates/settings/appointment-types.html',
    controller: 'appointmentCtrl',
    data: {
      pageTitle: 'settings.top_links.appointment_types',
      navlink: 'Appointment Types'
    }
  })
  .state('settings.appointment.info', {
    url: '/:appointmentID',
    templateUrl: '/templates/settings/appointment-types-info.html',
    controller: 'appointmentCtrl',
    data: {
      pageTitle: 'settings.top_links.appointment_types',
      navlink: 'Appointment Types'
    }
  })
  .state('settings.data-imports', {
    url: '/data-imports',
    templateUrl: '/templates/settings/data-imports.html',
    controller: 'dataImportCtrl',
    data: {
      pageTitle: 'settings.top_links.data_imports',
      navlink: 'Data Imports'
    }
  })
  .state('settings.data-imports-upload', {
    url: '/data_imports_upload/:dataType',
    templateUrl: '/templates/settings/data-imports-upload.html',
    controller: 'dataImportUploadCtrl',
    data: {
      pageTitle: 'settings.top_links.data_imports',
      navlink: 'Data Imports'
    }
  })
  .state('settings.data-imports-edit', {
    url: '/data_imports_edit/:dataType/:id',
    templateUrl: '/templates/settings/data-imports-upload.html',
    controller: 'dataImportUploadCtrl',
    data: {
      pageTitle: 'settings.top_links.data_imports',
      navlink: 'Data Imports'
    }
  })
  .state('settings.data-imports-list', {
    url: '/data-imports-list/:dataType/:importId',
    templateUrl: '/templates/settings/data-imports-list.html',
    controller: 'dataImportListCtrl',
    data: {
      pageTitle: 'settings.top_links.data_imports',
      navlink: 'Data Imports'
    }
  })
  .state('settings.data-export', {
    url: '/data-export',
    templateUrl: '/templates/settings/data-export.html',
    controller: 'dataExportCtrl',
    data: {
      pageTitle: 'settings.top_links.data_exports',
      navlink: 'Data Export'
    }
  })
  .state('settings.integration', {
    url: '/integration',
    templateUrl: '/templates/settings/integration.html',
    controller: 'integrationCtrl',
    data: {
      pageTitle: 'Integration',
      navlink: 'Data Export'
    }
  })
  .state('settings.document-and-printing', {
    url: '/document-and-printing',
    templateUrl: '/templates/settings/document-and-printing.html',
    controller: 'docPrintCtrl',
    data: {
      pageTitle: 'settings.top_links.documents_printing',
      navlink: 'Document & printing'
    }
  })
  .state('settings.letter-templates', {
    url: '/letter-templates',
    templateUrl: '/templates/settings/letter-templates.html',
    controller: 'letterTemplateCtrl',
    data: {
      pageTitle: 'settings.top_links.letter_templates',
      navlink: 'Letter Templates'
    }
  })
  .state('settings.letter-templates.info', {
    url: '/:letter_templates_id',
    templateUrl: '/templates/settings/letter-templates-info.html',
    controller: 'letterTemplateChildCtrl',
    data: {
      pageTitle: 'settings.top_links.letter_templates',
      navlink: 'Letter Templates'
    }
  })
  .state('settings.sms-templates', {
    url: '/sms-templates',
    templateUrl: '/templates/settings/sms-templates.html',
    controller: 'smsTemplateCtrl',
    data: {
      pageTitle: 'SMS Templates',
      navlink: 'SMS Templates'
    }
  })
  .state('settings.sms-templates.info', {
    url: '/:sms_templates_id',
    templateUrl: '/templates/settings/sms-templates-info.html',
    controller: 'smsTemplateChildCtrl',
    data: {
      pageTitle: 'SMS Templates',
      navlink: 'SMS Templates'
    }
  })
  .state('settings.billable-items', {
    url: '/billable-items',
    templateUrl: '/templates/settings/billable-items.html',
    controller: 'billableItemCtrl',
    data: {
      pageTitle: 'settings.top_links.billable_items',
      navlink: 'Billable Items'
    }
  })
  .state('settings.billable-items.info', {
    url: '/:bilable_id',
    templateUrl: '/templates/settings/billable-items-info.html',
    controller: 'billableItemChildCtrl',
    data: {
      pageTitle: 'settings.top_links.billable_items',
      navlink: 'Billable Items'
    }
  })
  .state('settings.appointment-reminders', {
    url: '/appointment-reminders',
    templateUrl: '/templates/settings/appointment-reminders.html',
    controller: 'appointmentReminderCtrl',
    data: {
      pageTitle: 'settings.top_links.appointment_reminders',
      navlink: 'Appointment Reminders'
    }
  })
  .state('settings.permission-matrix', {
    url: '/permission-matrix',
    templateUrl: '/templates/settings/permission-matrix.html',
    controller: 'permissionMatrixCtrl',
    data: {
      pageTitle: 'Permission Matrix',
      navlink: 'Permission Matrix'
    }
  })
  .state('products', {
    url: '/products',
    templateUrl: '/templates/products/products.html',
    controller: 'productCtrl',
    data: {
      pageTitle: 'product_title',
      navlink: 'Products',
      authRequire: true
    }
  })
  .state('products.new', {
    url: '/new',
    templateUrl: '/templates/products/addProducts.html',
    controller: 'add_edit_productCtrl',
    data: {
      pageTitle: 'product_title',
      navlink: 'Products'
    }
  })
  .state('products.edit', {
    url: '/edit/:pro_id',
    templateUrl: '/templates/products/addProducts.html',
    controller: 'add_edit_productCtrl',
    data: {
      pageTitle: 'product_title',
      navlink: 'Products'
    }
  })
  /*.state('products.list', {
    url: '/list',
    templateUrl: '/templates/products/product-list.html',
    controller: 'productListCtrl',
    data: {
      pageTitle: 'product_title',
      navlink: 'Products'
    }
  })*/
  /*.state('products.new', {
    url: '/new',
    templateUrl: '/templates/products/product-new.html',
    controller: 'productNew',
    data: {
      pageTitle: 'product_title',
      navlink: 'Products'
    }
  })*/
  .state('expense', {
    url: '/expense',
    templateUrl: '/templates/expense/expense.html',
    controller: 'expenseCtrl',
    data: {
      pageTitle: 'expense_title',
      navlink: 'Products',
      authRequire: true
    }
  })
  .state('expense.new', {
    url: '/new',
    templateUrl: '/templates/expense/addExpense.html',
    controller: 'add_edit_ExpenseCtrl',
    data: {
      pageTitle: 'expense_title',
      navlink: 'Products'
    }
  })
  .state('expense.edit', {
    url: '/edit/:ex_id',
    templateUrl: '/templates/expense/addExpense.html',
    controller: 'add_edit_ExpenseCtrl',
    data: {
      pageTitle: 'expense_title',
      navlink: 'Products'
    }
  })
  .state('communication', {
    url: '/communication',
    templateUrl: '/templates/communication/communication.html',
    controller: 'communicationCtrl',
    data: {
      pageTitle: 'Communication',
      navlink: 'Communication',
      authRequire: true
    }
  })
  .state('communication.new', {
    url: '/new',
    templateUrl: '/templates/communication/communication_new.html',
    controller: 'communicationCtrl',
    data: {
      pageTitle: 'Communication',
      navlink: 'Communication'
    }
  })
  .state('contact', {
    url: '/contact',
    templateUrl: '/templates/contact/contact.html',
    controller: 'contactCtrl',
    data: {
      pageTitle: 'Contact',
      navlink: 'Contact',
      authRequire: true
    }
  })
  .state('contact.new', {
    url: '/new',
    templateUrl: '/templates/contact/addContact.html',
    controller: 'add_edit_contactCtrl',
    data: {
      pageTitle: 'Contact',
      navlink: 'Contact'
    }
  })
  .state('contact.edit', {
    url: '/edit/:con_id',
    templateUrl: '/templates/contact/addContact.html',
    controller: 'add_edit_contactCtrl',
    data: {
      pageTitle: 'Contact',
      navlink: 'Contact'
    }
  })
  .state('patient', {
    url: '/patient',
    templateUrl: '/templates/patient/patient.html',
    controller: 'PatientCtrl',
    data: {
      pageTitle: 'Patients',
      navlink: 'Patient',
      authRequire: true
    }
  })
  .state('patient.new', {
    url: '/new',
    templateUrl: '/templates/patient/addPatient.html',
    controller: 'addEditPatientController',
    data: {
      pageTitle: 'Patients',
      navlink: 'Patient'
    }
  })
  .state('AccountStatement', {
    url: '/AccountStatementTest/:patient_id',
    templateUrl: '/templates/patient/AccountStatement.html',
    controller: 'AccountStatementCtrl',
    data: {
      pageTitle: 'AccountStatement',
      navlink: 'AccountStatement',
      authRequire: true
    }
  })

  .state('patient-detail', {
    url: '/patient-detail/:patient_id',
    templateUrl: '/templates/patient/patient-detail.html',
    controller: 'PatientDetailCtrl',
    data: {
      pageTitle: 'Patient Detail',
      navlink: 'Patient Detail',
      authRequire: true
    }
  })
  .state('patient-detail.edit', {
    url: '/edit',
    templateUrl: '/templates/patient/addPatient.html',
    controller: 'PatientEditCtrl',
    data: {
      pageTitle: 'Patients',
      navlink: 'Patient'
    }
  })
  .state('patient-detail.newPayment',{
    url: "/payment",
    templateUrl: "/templates/payment/addPayment.html", 
    controller: 'PaymentNewCtrl',
    data : { pageTitle: 'payment', navlink : 'payment'  }
  })
  .state('patient-detail.editPayment',{
    url: "/paymentEdit/:payment_id",
    templateUrl: "/templates/payment/editPayment.html", 
    controller: 'PaymentEditCtrl',
    data : { pageTitle: 'payment', navlink : 'payment'  }
  })
  .state('patient-detail.sendSms',{
    url: "/sendSms/:phone_no",
    templateUrl: "/templates/sms/sendSMS.html", 
    controller: 'sendsmsCtrl',
    data : { pageTitle: 'SMS'}
  })
  .state('patient-detail.newInvoice',{
    url: "/newInvoice",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('patient-detail.invoiceView',{
    url: "/invoiceView/:invoice_id",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('patient-detail.editInvoice',{
    url: "/editInvoice/:invoice_id",
    templateUrl: "/templates/invoice/editInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('patient-detail.invoicePayment',{
    url: "/newPayment/:invoice_id",
    templateUrl: "/templates/payment/addPayment.html", 
    controller: 'PaymentNewCtrl',
    data : { pageTitle: 'payment', navlink : 'payment'  }
  })
  .state('patient-detail.paymentView',{
    url: "/paymentView/:payment_id",
    templateUrl: "/templates/payment/addPayment.html", 
    controller: 'PaymentEditCtrl',
    data : { pageTitle: 'Payment', navlink : 'Payment'  }
  })
  .state('invoice',{
    url: "/invoice",
    templateUrl: "/templates/invoice/invoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice',authRequire: true  }
  })
  .state('invoice.new',{
    url: "/new",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('appointment.new_qs',{
    url: "/new/:app_id",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('invoice.edit',{
    url: "/:invoice_id/edit",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('invoice.view',{
    url: "/:invoice_id/view",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('appointment.invoiceView',{
    url: "/:invoice_id/invoiceView",
    templateUrl: "/templates/invoice/addInvoice.html", 
    controller: 'InvoiceCtrl',
    data : { pageTitle: 'invoices', navlink : 'invoice'  }
  })
  .state('payment', {
    url: "/payment",
    templateUrl: "/templates/payment/payment.html",
    controller: 'PaymentCtrl',
    data : { pageTitle: 'payment', navlink : 'payment',authRequire: true  }
  })

.state('payment.new',{
  url: "/new",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentNewCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
	
.state('payment.newPayment',{
  url: "/:patient_id/New",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentNewCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})

.state('payment.new.invoice',{
  url: "/:invoice_id",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('invoice.newPayment',{
  url: "/newPayment/:invoice_id",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentNewCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('invoice.viewPayment',{
  url: "/viewPayment/:payment_id",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentEditCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('appointment.newPayment',{
  url: "/newPayment/:invoice_id",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentNewCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('appointment.viewPayment',{
  url: "/viewPayment/:payment_id",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentEditCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('payment.edit',{
  url: "/:payment_id/edit",
  templateUrl: "/templates/payment/addPayment.html", 
  controller: 'PaymentEditCtrl',
  data : { pageTitle: 'payment', navlink : 'payment'  }
})
.state('payment.view',{
  url: "/:payment_id/view",
  templateUrl: "/templates/payment/Payment_view.html", 
  controller: 'PaymentViewCtrl',
  data : { pageTitle: 'Payment', navlink : 'Payment'  }
})
.state('appointment',{
  url: "/appointment",
  templateUrl: "/templates/appointment/appointment.html", 
  controller: 'appointmentModuleCtrl',
  data : { pageTitle: 'Appointment', navlink : 'Appointment',authRequire: true  }
})
.state('appointment.view',{
  url: "/:appointment_id",
  templateUrl: "/templates/appointment/appointment.html", 
  controller: 'appointmentModuleCtrl',
  data : { pageTitle: 'Appointment', navlink : 'Appointment'  }
})
.state('appointment.newInvoice',{
  url: "/newInvoice",
  templateUrl: "/templates/invoice/addInvoice.html", 
  controller: 'InvoiceCtrl',
  data : { pageTitle: 'invoices', navlink : 'invoice'  }
})
.state('appointment.appDate',{
  url: "/appointment/:appointment_date/:appointment_id",
  templateUrl: "/templates/appointment/appointment.html", 
  controller: 'appointmentModuleCtrl',
  data : { pageTitle: 'Appointment', navlink : 'Appointment'  }
})
.state('reports',{
  url: "/reports",
  templateUrl: "/templates/reports/reports.html", 
  controller: 'reportsCtrl',
  data : { pageTitle: 'Appointment', navlink : 'Reports',authRequire: true  }
})
.state('reports.appReports',{
  url: "/Appointment",
  templateUrl: "/templates/reports/appointmentReports.html", 
  controller: 'reportsModuleCtrl',
  data : { pageTitle: 'Appointment', navlink : 'Reports'  }
})
.state('reports.practitionarReports',{
  url: "/practitionar",
  templateUrl: "/templates/reports/practitionar_reports.html", 
  controller: 'practitionarReportsCtrl',
  data : { pageTitle: 'Practitioners', navlink : 'Reports'  }
})
.state('reports.patientReports',{
  url: "/patient",
  templateUrl: "/templates/reports/patientReports.html", 
  controller: 'patientReportsCtrl',
  data : { pageTitle: 'Patients', navlink : 'Reports'  }
})
.state('reports.recallPatientReports',{
  url: "/recallPatient",
  templateUrl: "/templates/reports/recallPatientReports.html", 
  controller: 'recallPatientReportsCtrl',
  data : { pageTitle: 'Recall Patients', navlink : 'Reports'  }
})
.state('reports.patientBirthdayReports',{
      url: "/patientBirthday",
      templateUrl: "/templates/reports/patientBirthdayReports.html", 
      controller: 'patientBirthdayReportsCtrl',
          data : { pageTitle: 'Patients Birthday', navlink : 'Reports'  }
    })
.state('reports.referralTypeReports',{
      url: "/referralType",
      templateUrl: "/templates/reports/referral_type_reports.html", 
      controller: 'referralTypeReportsCtrl',
          data : { pageTitle: 'Referral Type', navlink : 'Reports'  }
    })
.state('reports.revenueReports',{
      url: "/revenue",
      templateUrl: "/templates/reports/revenue_reports.html", 
      controller: 'revenueReportsCtrl',
          data : { pageTitle: 'Revenue', navlink : 'Reports'  }
    })
.state('reports.dailyPaymentReports',{
      url: "/dailyPayment",
      templateUrl: "/templates/reports/daily_payment_reports.html", 
      controller: 'dailyReportsCtrl',
      data : { pageTitle: 'Daily Payment Reports', navlink : 'Reports'  }
    })
.state('reports.expenseReports',{
      url: "/expense",
      templateUrl: "/templates/reports/expenseReports.html", 
      controller: 'expenseReportsCtrl',
      data : { pageTitle: 'Expense', navlink : 'Reports'  }
    })
.state('reports.PatientWithoutApp',{
      url: "/PatientWithoutApp",
      templateUrl: "/templates/reports/patientWithoutApp.html", 
      controller: 'PatientWithoutAppCtrl',
      data : { pageTitle: 'Patients Without Upcoming Appointments', navlink : 'Reports'  }
    })
.state('sms',{
      url: "/sms",
      templateUrl: "/templates/sms/sms.html", 
      controller: 'smsCtrl',
      data : { pageTitle: 'SMS Center',authRequire: true}
    })
.state('smsLogs',{
      url: "/smsLogs",
      templateUrl: "/templates/sms/smsLogs.html", 
      controller: 'smsLogsCtrl',
      data : { pageTitle: 'SMS Logs',authRequire: true}
    })
.state('sms.send',{
      url: "/send",
      templateUrl: "/templates/sms/sendSMS.html", 
      controller: 'sendsmsCtrl',
      data : { pageTitle: 'SMS'}
    })
.state('smsLogs.Contactview',{
      url: "/view/:contactType",
      templateUrl: "/templates/sms/smsView.html", 
      controller: 'viewSmsCtrl',
      data : { pageTitle: 'SMS'}
    })
.state('smsLogs.Userview',{
      url: "/userview/:userType",
      templateUrl: "/templates/sms/smsView.html", 
      controller: 'viewSmsCtrl',
      data : { pageTitle: 'SMS'}
    })
.state('smsLogs.Patientview',{
      url: "/viewpatient/:patientType",
      templateUrl: "/templates/sms/smsView.html", 
      controller: 'viewSmsCtrl',
      data : { pageTitle: 'SMS'}
    })
.state('smsLogs.unknownview',{
      url: "/viewUnknown/:unknownNo",
      templateUrl: "/templates/sms/smsView.html", 
      controller: 'viewSmsCtrl',
      data : { pageTitle: 'SMS'}
    })
  .state('contact.sendSMS', {
    url: '/:contact_id/sendSMS/:phone_no',
    templateUrl: '/templates/sms/sendSMS.html',
    controller: 'sendsmsCtrl',
    data: {
      pageTitle: 'SMS'
    }
  })

/*handeling $http erros */
/*commented for development */
 /*$httpProvider.interceptors.push(function($q) {
    return {
     'request': function(config) {
         // same as above
         return config
      },

      'response': function(response) {
         // same as above
         return response
      },
      'responseError': function(rejection) {
         console.log(rejection);
         location.href = '#!/error'
        // do something on error
        
        return $q.reject(rejection);
      }
    };
  });*/
});

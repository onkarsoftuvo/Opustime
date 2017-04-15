app.controller('InvoiceCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$filter',
  'lazyload',
  '$stateParams',
  '$timeout',
  '$q',
  '$translate',
  '$window',
  'pageService',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $filter, lazyload, $stateParams, $timeout, $q, $translate, $window, pageService) {
    
    init();

    function init(){
      $scope.paging = {};
      $scope.paging.fromFilter = '',
      $scope.paging.toFilter = '',
      $scope.paging.Page = 1;
      $scope.paging.TotalItems = 0;
      $scope.paging.PageSize = 30;
      $scope.showGrid = false;
    }

    $scope.current = 'active';
    $scope.editInvoice = false;
    $scope.editInvoiceForm = true;
    $scope.BilableItems = true;
    $scope.AddInvoice = true;
    $scope.header = {
      module:'controllerVeriable.invoice',
      title:'controllerVeriable.newInvoice',
      back_link: 'invoice',
    }
    if ($stateParams.patient_id) {
      $scope.header.back_link = 'patient-detail({"patient_id" : ' + $stateParams.patient_id + '})';
    }
    else if($stateParams.app_id){
      $scope.header.back_link = 'appointment';
    }
    $scope.invoice = {
      invoice_items_attributes: []
    }

    $rootScope.cloading = true;

    //Get new hit
    $scope.getPatientsData = function () {
      $rootScope.cloading = true;
      $http.get('/invoices/new').success(function (data) {
        $scope.invoice.notes = data.notes;
        $rootScope.cloading = false;
      });
    }
    $scope.getPatientsData();
    $scope.current_patient = $stateParams.patient_id;

    //Get patient
    $scope.getPatientsData = function () {
      $http.get('/list/patients').success(function (data) {
        data.forEach(function(patient){
            patient.fullName = patient.first_name+' '+patient.last_name;
          })
        $scope.PatientListData = data;
        $rootScope.cloading = false;
        if ($scope.current_patient != undefined) {
          $scope.filterPatient = $filter('filter') (data, $scope.current_patient);
          //$scope.PatientListData=$scope.filterPatient;
          $scope.invoice.patient = {
            first_name: $scope.filterPatient[0].first_name,
            last_name: $scope.filterPatient[0].last_name,
            id: $scope.filterPatient[0].id
          }
        }
        
      });
    }
    $scope.getPatientsData();

    //print invoice
    $scope.PrintInvoice = function (id) {
      var win = window.open('/invoices/' + id + '/print.pdf', '_blank');
      win.focus();
    }

    //email account statement to another email
    $scope.emailOther = function (id, data) {
      $rootScope.cloading = true;
      $http.get('/invoices/' + id + '/send_email?email_to=other').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      })
    }

    //email account statement to patient's email
    $scope.emailPatient = function (id, data) {
      $rootScope.cloading = true;
      $http.get('/invoices/' + id + '/send_email?email_to=patient').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      })
    }
    //get Appointments details
    $scope.getAppointmentDetails = function (id) {
      if (id) {
        $scope.GetPatientDetails({'id':$scope.invoice.patient.id})
        $http.get('/invoice/appointment_types/' + $scope.invoice.patient.id + '/' + id).success(function (results) {
          $scope.invoice.invoice_items_attributes.length = 0;
          $scope.appointmentData = results;
          $scope.appointmentData.billable_items.forEach(function (bilable_items) {
            bilable_items.item_id = bilable_items.item_id;
            bilable_items.item_type = 'BillableItem';
            $scope.invoice.invoice_items_attributes.push(bilable_items)
          });
          $scope.appointmentData.products.forEach(function (products) {
            products.item_id = products.item_id;
            products.item_type = 'Product'
            $scope.invoice.invoice_items_attributes.push(products)
          });
          $scope.Calculation();
        });
      }
    }

    //get AppointmentsType details
    $scope.getAppointmentTypeDetails = function (data) {
      var id;
      $q(function (resolve, reject) {
        setTimeout(function () {
          $scope.patient.appointment.forEach(function(apps){
          	if(apps.appointment_id = data){
          		$scope.AppointmenttypeID = apps.appointment_type_id;
          		id = apps.appointment_type_id;
          	}
          });
          if (id) {
            $http.get('/invoice/appointment_types/' + $scope.invoice.patient.id + '/' + id).success(function (results) {
              $scope.invoice.invoice_items_attributes.length = 0;
              $scope.appointmentData = results;
              $scope.appointmentData.billable_items.forEach(function (bilable_items) {
                bilable_items.item_id = bilable_items.item_id;
                bilable_items.item_type = 'BillableItem';
                $scope.invoice.invoice_items_attributes.push(bilable_items)
              });
              $scope.appointmentData.products.forEach(function (products) {
                products.item_id = products.item_id;
                products.item_type = 'Product'
                $scope.invoice.invoice_items_attributes.push(products)
              });
              $scope.Calculation();
            });
          }
        }, 1000);
      });
    }

    //Get practitioners
    $scope.getpractitioners = function () {
      $http.get('/practitioners').success(function (data) {
        $scope.practitioners = data;
        if(!$stateParams.app_id){
          $scope.first_practioner = $scope.practitioners[0].id;
          $scope.invoice.practitioner = $scope.practitioners[0].id;
        }
      });
    }
    $scope.getpractitioners()

    //Get Bussiness List
    $scope.GetBussiness = function () {
      Data.get('/list/businesses').then(function (results) {
        $scope.BussinessList = results;
        if (results.length == 1) {
          $scope.invoice.business = results[0].id;
        }
      });
    }
    $scope.GetBussiness();
    
    $scope.PatitionerListDataf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.practitioners, query)
    }

    //Get ProductList 
    $scope.getProductList = function () {
      $http.get('/list/products').success(function (list) {
        $scope.ProductsList = list;
      });
    }
    $scope.getProductList();

    //Add BillableProduct row
    $scope.addBillableProduct = function () {
      $scope.invoice.invoice_items_attributes.push({
        item_id: '',
        item_type: 'BillableItem',
        unit_price: '',
        quantity: '',
        tax: '',
        discount: '',
        total_price: '',
        tax_amount: '',
        discount_type_percentage: ''
      })
    }

    //Remove Product Row
    $scope.RemoveBillableProduct = function (index) {
      $scope.invoice.invoice_items_attributes.splice(index, 1)
      $scope.Calculation();
    }

    //Add Product row
    $scope.addProduct = function () {
      $scope.invoice.invoice_items_attributes.push({
        item_id: '',
        item_type: 'Product',
        unit_price: '',
        quantity: '',
        tax: '',
        discount: '',
        total_price: '',
        tax_amount: '',
        discount_type_percentage: ''
      })
    }

    $scope.new_Invoice = function () {
      $scope.new_invoice = true;
      $scope.AddInvoice = false;
      $scope.SaveCancelBtn = true;
      $scope.AddnewInvoice = true;
    }

    $scope.editInvoiceDetail = function(id){
      $state.go('invoice.edit', {invoice_id : id})
    }

    $scope.today = function () {
      $scope.invoice.issue_date = new Date();
    };
    $scope.today();

    $scope.open = function ($event) {
      $scope.status.opened = true;
    };

    $scope.cntry = '';
    $scope.country = '';
    /*Data.getCountry().then(function (results) {
      $scope.country = results;
      $http.get('http://ipinfo.io/json').success(function (results) {
        $rootScope.ipDetails = results;
        $scope.invoices.country = $rootScope.ipDetails.country;
        $scope.Toffset = new Date().getTimezoneOffset();
        $scope.GetStates($scope.invoices.country);
      });
    });
    $scope.GetStates = function(data){
    $scope.state = '';
     Data.getCountry().then(function (results) {
        $scope.countryf = results;
        $scope.Jfilename = filterFilter($scope.countryf, {code:data});
          Data.get('assets/angular/common/countries/'+$scope.Jfilename[0].filename+'.json').then(function (results) {
            $scope.state = results;
            $scope.Contact.state = results[0].code;
        });
    });
  };*/

    /*Data.getCountry().then(function (results) {
      $scope.country = results;
      console.log($scope.country);
      Data.getCurrentCountry().then(function (cntry) {
        console.log(cntry);
      })
    });*/
    
    //get current state
    $scope.currentCon = {};
    $scope.inData = {};
    function GetStates(con, state) {
      return Data.getCountry().then(function(results) {
        $scope.Jfilename = filterFilter(results, {code: con});
        return Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (results) {
          $scope.inState = filterFilter(results, {code: state});
          $scope.inData = {'country' : $scope.Jfilename[0].name, 'state' : $scope.inState[0].name};
          return $scope.inData;
        });
      });
      return $scope.inData;
    };

    /*$scope.countryName = function(con){
      console.log(con);
      $scope.GetStates(con)
    }*/

    //get all permissions
    function getPermissions(){
      $http.get('/invoices/security_roles').success(function(data){
        $rootScope.invPerm = data;
        if (!data.create && ($window.location.hash == '#!/invoice/new' || $window.location.hash == '#!/patient-detail/'+$stateParams.patient_id+'/newInvoice')) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard')
        }

        if (!data.view) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard')
        }
        else{
          $scope.getpractitioners();
          // $scope.GetInvoice();
          $scope.invoiceLogs($scope.paging);
        }
      });
    }
    getPermissions();

    //To display show info
    $scope.opened = function (index, id) {
      $rootScope.cloading = true;
      setTimeout(function () {
        $http.get('/invoices/' + id).success(function (result) {
            //localStorage.setItem('inv_sub_total', result.subtotal);
          if (result.business.country != null && result.business.country != '') {
            $scope.Jfilename = filterFilter($scope.country, {
              code: result.business.country
            });
            if ($scope.Jfilename.length) {
              Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (list) {
                $scope.state = list;
                $scope.InvoiceDetails = result;
                $rootScope.cloading = false;
              });
            } 
            else {
              $scope.InvoiceDetails = result;
              $rootScope.cloading = false;
            }
          } 
          else {
            $scope.InvoiceDetails = result;
            $rootScope.cloading = false;
          }
        });
      })
    }

    //$scope.patientIds = 0;
    $scope.status = {
      opened: false,
    };

    //Patient Details in patientId 
    $scope.invoice.appointment = '';
    $scope.GetPatientDetails = function (value) {
      var practitioner_id = $scope.first_practioner;
      if(!$scope.first_practioner){
        practitioner_id = $scope.invoice.practitioner
      }
      $scope.current_patient_id = value.id;
      if (value != undefined)
      {
        $http.get('/appointments/' + value.id + '/' + practitioner_id + '?bs=' + $scope.invoice.business).success(function (list) {
          $scope.patient = list;
          $rootScope.credit_balance = list.credit_bal;
          if (list.appointment) {
            if (list.appointment.length) {
              $scope.invoice.type_appointment = 'Appointment';
            }
            else if (list.appointment_type.length) {
              $scope.invoice.type_appointment = 'AppointmentType';
            }
            $scope.invoice.invoice_to = list.patient.invoice_to;
            $scope.invoice.extra_patient_info = list.patient.invoice_extra_info;
          }
          /*if(!$stateParams.app_id){
            $scope.invoice.appointment = '';
          }*/
          $rootScope.credit_balance = list.credit_bal;
          $scope.patientIds = value.id;
          $rootScope.getBilable();
        });
      }
    }

    $scope.formatLabel = function(value){
      if(!value){
        return;
      }
      return value.first_name +' '+value.last_name;
    }
    //Patient Details in patientId
    $scope.GetPractionerDetails = function (value, bus) {
      $scope.first_practioner = value;

      if (value != undefined && bus != undefined ){

          $http.get('/appointments/' + $scope.current_patient_id + '/' + value + '?bs=' + $scope.invoice.business).success(function (list) {

          $scope.patient = list;
          if (list.appointment.length) {
            $scope.invoice.type_appointment = 'Appointment';
          }
          else if (list.appointment_type.length) {
            $scope.invoice.type_appointment = 'AppointmentType';
          }
          if(!$stateParams.app_id){
            $scope.invoice.appointment = '';
            $scope.invoice.invoice_to = list.patient.invoice_to;
            $scope.invoice.extra_patient_info = list.patient.invoice_extra_info;
          }
          $scope.patientIds = value.id;
          $rootScope.getBilable();
        });
      }
    }

    //Create Invoices

    $scope.CreateInvoice = function (data , flag ) {
      if (flag == true) {
          $scope.flag = true

      }
          else{
          $scope.flag = false
      }
      data.issue_date = new Date(data.issue_date);
      var new_Date_month = data.issue_date.getMonth() + 1;
      var new_Date_day = data.issue_date.getDate();
      if (new_Date_month < 10)
        new_Date_month = '0' + new_Date_month;
      if (new_Date_day < 10)
        new_Date_day = '0' + new_Date_day;
      data.issue_date = data.issue_date.getFullYear() + '-' + new_Date_month + '-' + new_Date_day;
      $rootScope.cloading = true;
      if ($scope.invoice.type_appointment == 'Appointment' && $scope.invoice.appointment!='') {
        $scope.app_data = JSON.parse(data.appointment);
        //$scope.app_Id = $scope.app_data.appointment_id;
        data.appointment = data.appointment;
      }
      $http.post('/invoices/', {
        invoice: data ,
        flag: $scope.flag ,
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
        else {
            var promise = $scope.invoiceLogs($scope.paging);
            promise.then(function(greeting) {
                $translate('toast.invoiceAddedd').then(function (msg) {
                    $rootScope.showSimpleToast(msg);
                });
            });
            if($rootScope.credit_balance >= data.subtotal && flag == true){
                if ($stateParams.app_id)
                  $state.go('appointment.invoiceView', { 'invoice_id': results.id});
                else if ($state.current.name == 'appointment.invoiceView')
                  $state.go('appointment');
                else if ($state.current.name == 'invoice.new')
                  $state.go('invoice.edit', { 'invoice_id': results.id});
                else
                  $state.go('patient-detail', { 'patient_id':data.patient.id}, { reload: true});
            }else{
                // var promise = $scope.GetInvoice();
                var promise = $scope.invoiceLogs($scope.paging);
                promise.then(function(greeting){
                    $translate('toast.invoiceAddedd').then(function (msg) {
                        $rootScope.showSimpleToast(msg);
                    });

                    $scope.noData = false;
                    $rootScope.cloading = false;
                    $rootScope.InvoiceList = $rootScope.InvoiceList;

                    if ($stateParams.patient_id) {
                        $state.go('patient-detail.invoicePayment', {
                            'invoice_id': results.id
                        }, {reload: true});
                        $rootScope.filterClientFiles($rootScope.ChkData);
                        $rootScope.CountClientFile();
                    }
                    else if($stateParams.app_id){
                        $rootScope.getEvents();
                        $state.go('appointment.newPayment', {
                            'invoice_id': results.id
                        });
                    }
                    else{
                        // $scope.GetInvoice();
                        $scope.invoiceLogs($scope.paging);
                        $state.go('invoice.newPayment', {
                            'invoice_id': results.id
                        });
                    }
                });
            }
        }
      });
    }

      $scope.checkCreditBalance = function (data) {
        var patient_id;
        if ($stateParams.invoice_id) {
          if ($scope.InvoiceDetails.invoice_amount < data.invoice_amount) {
            if ($stateParams.patient_id == undefined) {
                $scope.GetPatientDetails(data.patient);
                patient_id = data.patient.id;
            }
            else {
                $scope.GetPatientDetails({id: $stateParams.patient_id});
                patient_id = $stateParams.patient_id;
            }
            $http.get('/appointments/' + patient_id + '/' + data.practitioner + '?bs=' + $scope.invoice.business).success(function (list) {
              $rootScope.credit_balance = list.credit_bal;
              $rootScope.invoice_data = data;
              //localStorage.setItem('current_invoice_amnt', data.subtotal);
                if ($rootScope.credit_balance <= 0) {
                    $scope.CreateInvoice(data , false);
                } else {
                    $rootScope.modalInstance = $modal.open({
                        animation: $scope.animationsEnabled,
                        templateUrl: 'creditBalance.html',
                        size: 'md'
                    });
                }
            });
          } else {
              if ($stateParams.patient_id == undefined) {
                  $scope.GetPatientDetails(data.patient);
                  patient_id = data.patient.id;
              }
              else {
                  $scope.GetPatientDetails({id: $stateParams.patient_id});
                  patient_id = $stateParams.patient_id;
              }
              $http.get('/appointments/' + patient_id + '/' + data.practitioner + '?bs=' + $scope.invoice.business).success(function (list) {
                $rootScope.credit_balance = list.credit_bal;
                $rootScope.invoice_data = data;
                  //localStorage.setItem('current_invoice_amnt', data.subtotal);
                $scope.CreateInvoice(data , false);
              });
          }
        } else {
            if ($stateParams.patient_id == undefined) {
                $scope.GetPatientDetails(data.patient);
                patient_id = data.patient.id;
            }
            else {
                $scope.GetPatientDetails({id: $stateParams.patient_id});
                patient_id = $stateParams.patient_id;
            }
              $http.get('/appointments/' + patient_id + '/' + data.practitioner + '?bs=' + $scope.invoice.business).success(function (list) {
                $rootScope.credit_balance = list.credit_bal;
                $rootScope.invoice_data = data;
                  //localStorage.setItem('current_invoice_amnt', data.subtotal);
                if ($rootScope.credit_balance <= 0) {
                    $scope.CreateInvoice(data , false);
                } else {
                    $rootScope.modalInstance = $modal.open({
                        animation: $scope.animationsEnabled,
                        templateUrl: 'creditBalance.html',
                        size: 'md'
                    });
                }
              });
        }
      }

    $rootScope.createInvoiceCreditBal = function () {
        $rootScope.modalInstance.close($scope.CreateInvoice($rootScope.invoice_data, true ));
    };
    $rootScope.createInvoiceCreditBalCancel = function () {
        $rootScope.modalInstance.close($scope.CreateInvoice($rootScope.invoice_data, false ));
    };

    //Billable Item List
    $rootScope.getBilable = function () {
      Data.get('/patient/' + $scope.patientIds + '/billable_items').then(function (results) {
        $scope.BilableItemsList = results;
      });
    }
    $rootScope.getBilable();

    $scope.pagging = [];
    $scope.noData = false;
    $scope.lazyload_config = lazyload.config();
    
    $scope.BussinessListf = function (query) {

      query = angular.lowercase(query)
      return $filter('filter') ($scope.BussinessList, query)
    }

    $scope.show_concession=false;
    $scope.BillableItemDetails = function (invoices) {

      if (invoices.item_id != null)
      {
        angular.forEach($scope.BilableItemsList, function (p) {

          if (p.item_id == invoices.item_id) {

            invoices.unit_price = p.unit_price;
            invoices.total_price = p.total_price;
            invoices.quantity = p.quantity;
            invoices.tax = p.tax;
            invoices.tax_amount = p.tax_amount;
            invoices.discount = p.discount;
            $scope.CalculateTax = p.tax;
            //Concession
            if (p.concession == true)
            {
              invoices.show_concession = true;
              invoices.concession = p.concession_id;
              invoices.concession_name = 'Discount Type: ' + p.concession_name;
              //$scope.invoice.invoice_items_attributes.concession_id = p.concession_id
            } 
            else
            {
              invoices.show_concession = false;
              invoices.concession_name = '';
              invoices.concession = null;
            }
            $scope.Calculation();
          }
        })
      }
      else
      {
        invoices.unit_price = '';
        invoices.total_price = '';
        invoices.quantity = '';
        invoices.tax = '';
        invoices.discount = '';
        $scope.Calculation();
      }
    }

    $scope.Calculation = function () {
      //modal parameters
      $scope.CalculateTax = 0;
      $scope.invoice.total_discount = 0;
      $scope.invoice.subtotal = 0;
      $scope.invoice.tax = 0;
      $scope.invoice.invoice_amount = 0;
      for (var i = 0; i < $scope.invoice.invoice_items_attributes.length; i++) {
        if ($scope.invoice.invoice_items_attributes[i].total_price >= 0) {
          if ($scope.invoice.invoice_items_attributes[i].tax != 'N/A') {
            if ($scope.invoice.invoice_items_attributes[i].discount != undefined && $scope.invoice.invoice_items_attributes[i].discount != '') {
              if ($scope.invoice.invoice_items_attributes[i].discount_type_percentage != '$') {
                $scope.Cal_unit_price = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
                $scope.Actualtax = (parseFloat($scope.Cal_unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
                $scope.SubTot = parseFloat($scope.Cal_unit_price) + parseFloat($scope.Actualtax);
                $scope.Cal_Disc = (parseFloat($scope.invoice.invoice_items_attributes[i].discount) * parseFloat($scope.SubTot)) / 100;
                $scope.TotalPrice = parseFloat($scope.SubTot) - parseFloat($scope.Cal_Disc);
                $scope.invoice.invoice_items_attributes[i].total_price = $scope.TotalPrice.toFixed(2);
                $scope.Final_SubPrice = parseFloat($scope.TotalPrice) / (1 + parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount) / 100)
                $scope.FInalTax = (parseFloat($scope.TotalPrice) - parseFloat($scope.Final_SubPrice));
                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.Cal_Disc)).toFixed(2);
                $scope.invoice.invoice_amount = (parseFloat($scope.invoice.invoice_amount) + parseFloat($scope.TotalPrice)).toFixed(2);
                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Final_SubPrice)).toFixed(2);
                $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.FInalTax)).toFixed(2);
              } 
              else {
                $scope.Cal_unit_price = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
                $scope.Actualtax = (parseFloat($scope.Cal_unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
                $scope.SubTot = parseFloat($scope.Cal_unit_price) + parseFloat($scope.Actualtax);
                $scope.Cal_Disc = parseFloat($scope.invoice.invoice_items_attributes[i].discount);
                $scope.TotalPrice = parseFloat($scope.SubTot) - parseFloat($scope.Cal_Disc);
                $scope.invoice.invoice_items_attributes[i].total_price = $scope.TotalPrice.toFixed(2);
                $scope.Final_SubPrice = parseFloat($scope.TotalPrice) / (1 + parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount) / 100)
                $scope.FInalTax = (parseFloat($scope.TotalPrice) - parseFloat($scope.Final_SubPrice));
                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.Cal_Disc)).toFixed(2);
                $scope.invoice.invoice_amount = (parseFloat($scope.invoice.invoice_amount) + parseFloat($scope.TotalPrice)).toFixed(2);
                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Final_SubPrice)).toFixed(2);
                $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.FInalTax)).toFixed(2);
              }
              if ($scope.invoice.invoice_items_attributes[i].discount < 0) {
                $scope.invoice.total_discount = 'error';
                $scope.invoice.subtotal = 'error';
                $scope.invoice.tax = 'error';
                $scope.invoice.invoice_amount = 'error';
              }
            } 
            else {
              $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
              $scope.Caltax = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
              $scope.Actualtax = (parseFloat($scope.Caltax) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
              $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Caltax)).toFixed(2);
              $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.Actualtax)).toFixed(2);
              $scope.totprice = parseFloat($scope.invoice.tax) + parseFloat($scope.invoice.subtotal);
              $scope.invoice.invoice_amount = parseFloat($scope.totprice);
              $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
              $scope.invoice.invoice_items_attributes[i].total_price = ($scope.Actualtax + $scope.totalpri).toFixed(2);
              $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
              $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
              $scope.invoice.tax = parseFloat($scope.invoice.tax);
              $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
            }
          } 
          else {
            if ($scope.invoice.invoice_items_attributes[i].discount != undefined && $scope.invoice.invoice_items_attributes[i].discount != '') {
              if ($scope.invoice.invoice_items_attributes[i].discount_type_percentage != '$') {
                $scope.Caldiscount = parseFloat($scope.invoice.invoice_items_attributes[i].discount) * parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
                $scope.ActualDiscount = (parseFloat($scope.Caldiscount) / 100);
                $scope.discount_type_percentagel = parseFloat($scope.ActualDiscount) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.discount_type_percentagel)).toFixed(2);
                $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) - parseFloat($scope.ActualDiscount);
                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity))).toFixed(2);
                $scope.totprice = (parseFloat($scope.invoice.subtotal));
                $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
                $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
                $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
                $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
                $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
                $scope.invoice.tax = parseFloat($scope.invoice.tax);
                $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
              } 
              else {
                $scope.invoice.total_discount = parseFloat($scope.invoice.invoice_items_attributes[i].discount).toFixed(2);
                $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity) - parseFloat($scope.invoice.total_discount))).toFixed(2);
                $scope.totprice = (parseFloat($scope.invoice.subtotal));
                $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
                $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity) - parseFloat($scope.invoice.total_discount);
                $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
                $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
                $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
                $scope.invoice.tax = parseFloat($scope.invoice.tax);
                $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
              }
              if ($scope.invoice.invoice_items_attributes[i].discount < 0) {
                $scope.invoice.total_discount = 'error';
                $scope.invoice.subtotal = 'error';
                $scope.invoice.tax = 'error';
                $scope.invoice.invoice_amount = 'error';
              }
            } 
            else {
              $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
              $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity))).toFixed(2);
              $scope.totprice = parseFloat($scope.invoice.subtotal);
              $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
              $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
              $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
              $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
              $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
              $scope.invoice.tax = parseFloat($scope.invoice.tax);
              $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
            }
          }
        }
      }
      if(isNaN($scope.invoice.subtotal)){
        $scope.invoice.subtotal='Error';
      }
      if(isNaN($scope.invoice.tax)){
        $scope.invoice.tax='Error';
      }
      if(isNaN($scope.invoice.total_discount)){
        $scope.invoice.total_discount='Error';
      }
      if(isNaN($scope.invoice.invoice_amount)){
        $scope.invoice.invoice_amount='Error';
      }
    }
    $scope.Calculation();

    $scope.ProductDetails = function (invoices) {

      if (invoices.item_id != null)
      {
        angular.forEach($scope.ProductsList, function (p) {
          if (p.item_id == invoices.item_id) {
            invoices.unit_price = p.unit_price;
            invoices.total_price = p.total_price;
            invoices.quantity = p.quantity;
            invoices.tax_amount = p.tax_amount;
            invoices.tax = p.tax;
            invoices.discount = p.discount;
            $scope.Calculation();
          }
        })
      } 
      else
      {
        invoices.unit_price = '';
        invoices.total_price = '';
        invoices.quantity = '';
        invoices.tax = '';
        invoices.discount = '';
        $scope.Calculation();
      }
    }

    $rootScope.DeleteInvoice = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/invoices/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
        if ($stateParams.patient_id) {
            $state.go('patient-detail',{"patient_id" : $stateParams.patient_id});
            $rootScope.filterClientFiles($rootScope.ChkData);
            $rootScope.CountClientFile();
          }
        else {
          $rootScope.cloading = false;
          $state.go('invoice');
          $translate('toast.invoiceDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $scope.new_pati = false;
          // $scope.GetInvoice();
          $scope.invoiceLogs($scope.paging);
        }
      })
    }

    $scope.DeleteInvoice = function (size, id, events) {
      $rootScope.pat_id = id;
      $rootScope.pat_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };

    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($rootScope.DeleteInvoice($rootScope.pat_id, $rootScope.pat_events));
    };

    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };

    //get Appointments details
    if($stateParams.app_id){
      $rootScope.cloading = true;
      Data.get('/appointments/' + $stateParams.app_id).then(function (results) {
        $scope.appointmentsDetails = results.appointment;
        $scope.invoice.patient=$scope.appointmentsDetails.patient;
        $scope.invoice.practitioner=$scope.appointmentsDetails.practitioner_id;
        // $scope.GetPractionerDetails($scope.appointmentsDetails.practitioner_id);
        $scope.invoice.business=$scope.appointmentsDetails.business;
        // $scope.GetPatientDetails($scope.appointmentsDetails.patient);
        //$scope.invoice.appointment=JSON.stringify($scope.appointmentsDetails.appnt_info);
        $scope.invoice.appointment=JSON.stringify($scope.appointmentsDetails.appnt_info.appointment_id);
        if($scope.appointmentsDetails.appnt_info.type=='appointment'){
          var chechStatus=$scope.getAppointmentTypeDetails($scope.appointmentsDetails.appnt_info);
          chechStatus.then(function (greeting) {
            $scope.invoice.practitioner=$scope.appointmentsDetails.practitioner_id;
          });
        }
        else{
          $scope.getAppointmentDetails($scope.appointmentsDetails.appnt_info.appointment_type_id);
        }
        $rootScope.cloading = false;
      });
    }

    // $scope.GetInvoice = function () {
    //   return  $q(function (resolve, reject) {
    //     setTimeout(function () {
    //       Data.get('/invoices').then(function (results) {
    //         $scope.total_invoices = 0;
    //         $scope.total_outstanding = 0;
    //         $rootScope.InvoiceList = results;
    //         resolve();
    //         if ($rootScope.InvoiceList.invoices.length == 0) {
    //           $scope.noModule = true;
    //           $scope.noData = true;
    //         }
    //         else{
    //           $scope.noModule = false;
    //           $scope.noData = false;
    //         }
    //         $scope.pagging = [];
    //         for (i = 1; i <= $rootScope.InvoiceList.pagination.total_pages; i++) {
    //           $scope.pagging.push({
    //             pageNo: i
    //           });
    //         }
    //          /* $rootScope.InvoiceList.forEach(function (invoice) {
    //             $scope.total_invoices = parseFloat(invoice.invoice_amount + $scope.total_invoices).toFixed(2);
    //             $scope.total_outstanding = parseFloat((invoice.outstanding_balance + $scope.total_outstanding).toFixed(2));
    //           });*/
    //       });
    //     });
    //   }, 1000);
    // }

    //get invoice list
    $scope.invoiceLogs = function(pagingData) {
      $rootScope.InvoiceList = [];
      // obj = $http.get('/sms_center/logs');
      return  $q(function (resolve, reject) {
        setTimeout(function () {
      if(pagingData.fromFilter == "") {
        obj = Data.get('/invoices?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = Data.get('/invoices?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.then(function(results){
        if(results.invoices.length != 0){
          $rootScope.InvoiceList = results.invoices;
          $scope.InvoiceDetail = results;
          $scope.paging.TotalItems = results.total;
          resolve();
          $scope.showGrid = true;
          $scope.noRecordFount = false;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
      });
      }, 1000);
    });
    }

    //pagination code---------------------------------------------------
    
    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.paging = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.paging = pagingData;
      $scope.invoiceLogs($scope.paging);
    });

    function setPager() {
      pageService.setPaging($scope.paging);
    };

    //pagination ends here---------------------------------------------------- 

    //Clear invoice logs
    $scope.clearLogs = function() {
      $scope.paging.fromFilter = "";
      $scope.invoiceLogs($scope.paging); 
    }

    //filter for invoice search list
    // $scope.noRecordFount = false;
    // var _timeout;
    // $scope.invoiceSearch = function (Term) {
    //   console.log('Here the search apply filter: ', Term);
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     $http.get('/invoices?q=' + Term).success(function (data) {
    //       console.log('Here the return data: ',data);
    //       $rootScope.InvoiceList = data;
    //       if ($rootScope.InvoiceList.invoices.length == 0) {
    //         $scope.noRecordFount = true;
    //         $scope.noModule = false;
    //       } 
    //       else {
    //         $scope.noRecordFount = false;
    //       }
    //       $rootScope.cloading = false;
    //     });
    //     _timeout = null;
    //   }, 1000);
    // }

    if ($stateParams.invoice_id) {
    	var currentLink = window.location.href.split('/');
	    $scope.editInvoice = true;
	    $scope.hv_next_pre = true;
	    $scope.editInvoiceForm = false;
	    $scope.invoice = {};
	    $scope.header = {};
	    $scope.header = {
	      module:'controllerVeriable.invoice',
	      title:'Summary',
	      back_link: 'invoice',
	    }
	    currentLink.forEach(function(subLink){
	      if (subLink == 'invoiceView') {
	        $scope.header.title = 'View Invoice';
	      }
	    })
	    if ($stateParams.patient_id) {
	      $scope.header.back_link = 'patient-detail({"patient_id" : ' + $stateParams.patient_id + '})'
	    }
	    else if($state.includes('appointment')){
	      $scope.header.back_link = 'appointment';
	    }

	    $scope.openPaymentView = function(id){
	      if ($state.includes('appointment')) {
	        $state.go('appointment.viewPayment', {'payment_id' : id});
	      }
	      else{
	        $state.go('invoice.viewPayment', {'payment_id' : id});
	      }
	    }
	    $scope.GetInvoiceDetails = function () {
        $http.get('/invoices/' + $stateParams.invoice_id + '/edit').success(function (data) {
            localStorage.setItem('inv_sub_total', data.invoice.subtotal);
	        $scope.list_appointment = data.appointment_list;
          if (data.invoice) {
            $scope.getBilable(data.invoice.patient.id);
            $scope.invoice = data.invoice;
            $scope.initialInvoice = angular.copy($scope.invoice)
            // $scope.GetPatientDetails(data.invoice.patient.id);
          }
	        
	      });
	    }
	    // check NaN
	    $scope.checkNumber=function(args){
	      return checkNumber.checkNumb(args);
	    }
	    $scope.doEdit = function(){
	      $scope.editInvoiceForm = true;
	      $scope.header.title = 'controllerVeriable.editInvoice';
	    }
	    
	    //print invoice
	    $scope.PrintInvoice = function (id) {
	      var win = window.open('/invoices/' + id + '/print.pdf', '_blank');
	      win.focus();
	    }
	    //email account statement to another email

	    $scope.emailOther = function (id, data) {
	      $rootScope.cloading = true;
	      $http.get('/invoices/' + id + '/send_email?email_to=other').success(function (results) {
	        $rootScope.cloading = false;
	        $translate('toast.emailSentSuccess').then(function (msg) {
	          $rootScope.showSimpleToast(msg);
	        });
	      })
	    }
	    //email account statement to patient's email

	    $scope.emailPatient = function (id, data) {
	      $rootScope.cloading = true;
	      $http.get('/invoices/' + id + '/send_email?email_to=patient').success(function (results) {
	        $rootScope.cloading = false;
	        $translate('toast.emailSentSuccess').then(function (msg) {
	          $rootScope.showSimpleToast(msg);
	        });
	      })
	    }

	    //get invoice Detail
	    $scope.country = '';
	    $scope.invoiceDetail = function (id) {
	      $rootScope.cloading = true;
	      $http.get('/invoices/' + id).success(function (result) {
          $scope.currentCon = GetStates(result.business.country, result.business.state);
	        if ($scope.editInvoice) {
	          $scope.header.subtitle = 'Invoice Amount : $' + result.invoice_amount + ' //' + 'Outstanding Amount : $' + result.outstanding_balance;
	        }
	        else{
	          $scope.header.subtitle = ''; 
	        }
	        if (result.business.country != null && result.business.country != '') {
	          $scope.Jfilename = filterFilter($scope.country, {
	            code: result.business.country
	          });
	          if ($scope.Jfilename.length) {
	            Data.get('assets/angular/common/countries/' + $scope.Jfilename[0].filename + '.json').then(function (list) {
	              $scope.state = list;
	              $scope.InvoiceDetails = result;
	              $rootScope.cloading = false;
	            });
	          } 
	          else {
	            $scope.InvoiceDetails = result;
	            $rootScope.cloading = false;
	          }
	        } 
	        else {
	          $scope.InvoiceDetails = result;
	          $rootScope.cloading = false;
	        }
          if($scope.InvoiceDetails.payment_method.length == 1) {
            $scope.InvoiceDetails.payment_method[0].payment_date = new Date($scope.InvoiceDetails.payment_method[0].payment_date);
          } else if($scope.InvoiceDetails.payment_method.length > 1) {
            for (var i = 0; i < $scope.InvoiceDetails.payment_method.length; i++) {
              $scope.InvoiceDetails.payment_method[i].payment_date =  new Date($scope.InvoiceDetails.payment_method[i].payment_date);
            }
          }
	      });
	    }
	    $scope.invoiceDetail($stateParams.invoice_id);


	    //get Appointments details

	    // $scope.getAppointmentDetails = function (id) {
	    //   if (id) {
	    //     $http.get('/invoice/appointment_types/' + $scope.invoice.patient.id + '/' + id).success(function (results) {
	    //       $scope.invoice.invoice_items_attributes.length = 0;
	    //       $scope.appointmentData = results;
	    //       $scope.appointmentData.billable_items.forEach(function (bilable_items) {
	    //         bilable_items.item_id = '' + bilable_items.item_id;
	    //         bilable_items.item_type = 'BillableItem';
	    //         $scope.invoice.invoice_items_attributes.push(bilable_items)
	    //       });
	    //       $scope.appointmentData.products.forEach(function (products) {
	    //         products.item_id = '' + products.item_id;
	    //         products.item_type = 'Product'
	    //         $scope.invoice.invoice_items_attributes.push(products)
	    //       });
	    //       $scope.Calculation();
	    //     });
	    //   }
	    // }
	    //get AppointmentsType details

	    $scope.getAppointmentTypeDetails = function (data) {
	      var id;
	      $scope.AppointmenttypeID = data.appointment_type_id;
	      $scope.patient.appointment.forEach(function(apps){
          	if(apps.appointment_id = data){
          		$scope.AppointmenttypeID = apps.appointment_type_id;
          		id = apps.appointment_type_id;
          	}
          });
	      if (id) {
	        $http.get('/invoice/appointment_types/' + $scope.invoice.patient.id + '/' + id).success(function (results) {
	          $scope.invoice.invoice_items_attributes.length = 0;
	          $scope.appointmentData = results;
	          $scope.appointmentData.billable_items.forEach(function (bilable_items) {
	            bilable_items.item_id = bilable_items.item_id;
	            bilable_items.item_type = 'BillableItem';
	            $scope.invoice.invoice_items_attributes.push(bilable_items)
	          });
	          $scope.appointmentData.products.forEach(function (products) {
	            products.item_id = products.item_id;
	            products.item_type = 'Product'
	            $scope.invoice.invoice_items_attributes.push(products)
	          });
	          $scope.Calculation();
	        });
	      }
	    }
	    $scope.getBilable = function (id) {
	      var clientId = '';
	      if (id) {
	        clientId = id;
	      } 
	      else if ($scope.invoice.patient.id) {
	        clientId = $scope.invoice.patient.id
	      }
	      Data.get('/patient/' + clientId + '/billable_items').then(function (results) {
	        $scope.BilableItemsList = results;
	        $scope.BilableItemsList.forEach(function (BilableItemsList) {
	          BilableItemsList.item_id = '' + BilableItemsList.item_id;
	        });
	      });
	    }
	    //Get patient

	    $scope.getPatientsData = function () {
	      $http.get('/list/patients').success(function (data) {
	        $scope.PatientListData = data;
	      });
	    }
	    $scope.getPatientsData();
	    //Get Bussiness List
	    // $rootScope.GetBussiness = function () {
	    //   Data.get('/list/businesses').then(function (results) {
	    //     $scope.BussinessList = results;
	    //   });
	    // }
	    // $rootScope.GetBussiness();
	    //Get practitioners
	    $scope.getpractitioners = function () {
	      $http.get('/practitioners').success(function (data) {
	        $scope.practitioners = data;
	      });
	    }
	    $scope.getpractitioners();
	    //Get ProductList 
	    $scope.getProductList = function () {
	      $http.get('/list/products').success(function (list) {
	        $scope.ProductsList = list;
	        $scope.ProductsList.forEach(function (ProductsList) {
	          ProductsList.item_id = '' + ProductsList.item_id;
	        });
	        $scope.GetInvoiceDetails();
	      });
	    }
	    $scope.getProductList();
	    $scope.ProductDetails = function (invoices) {
	      if (invoices.item_id != null)
	      {
	        angular.forEach($scope.ProductsList, function (p) {
	          if (p.item_id == invoices.item_id) {
	            invoices.unit_price = p.unit_price;
	            invoices.total_price = p.total_price;
	            invoices.quantity = p.quantity;
	            invoices.tax_amount = p.tax_amount;
	            invoices.tax = p.tax;
	            invoices.discount = p.discount;
	            $scope.Calculation();
	          }
	        })
	      } 
	      else
	      {
	        invoices.unit_price = '';
	        invoices.total_price = '';
	        invoices.quantity = '';
	        invoices.tax = '';
	        invoices.discount = '';
	        $scope.Calculation();
	      }
	    }
	    $scope.BillableItemDetails = function (invoices) {
	      if (invoices.item_id != null)
	      {
	        angular.forEach($scope.BilableItemsList, function (p) {
	          if (p.item_id == invoices.item_id) {
	            invoices.unit_price = p.unit_price;
	            invoices.total_price = p.total_price;
	            invoices.quantity = p.quantity;
	            invoices.tax = p.tax;
	            invoices.tax_amount = p.tax_amount;
	            invoices.discount = p.discount;
	            $scope.CalculateTax = p.tax;
	            //Concession
	            /*if (p.concession == true)
	            {
	              $scope.Concession_Name = 'Concession Type: ' + p.concession_name;
	              $scope.invoice.invoice_items_attributes.concession_id = p.concession_id
	            } 
	            else
	            {
	              $scope.Concession_Name = '';
	            }*/
              if (p.concession == true)
              {
                invoices.show_concession = true;
                invoices.concession_name = 'Discount Type: ' + p.concession_name;
                invoices.concession = p.concession_id;
                //$scope.invoice.invoice_items_attributes.concession_id = p.concession_id
              } 
              else
              {
                invoices.show_concession = false;
                invoices.concession_name = '';
                invoices.concession = null;
              }
	            $scope.Calculation();
	          }
	        })
	      } 
	      else
	      {
	        invoices.unit_price = '';
	        invoices.total_price = '';
	        invoices.quantity = '';
	        invoices.tax = '';
	        invoices.discount = '';
	        $scope.Calculation();
	      }
	    }
	    $scope.addBillableProduct = function () {
	      $scope.invoice.invoice_items_attributes.push({
	        item_id: '',
	        item_type: 'BillableItem',
	        unit_price: '',
	        quantity: '',
	        tax: '',
	        discount: '',
	        total_price: '',
	        tax_amount: '',
	        discount_type_percentage: ''
	      })
	    }
	    //Remove Product Row

	    $scope.RemoveBillableProduct = function (index) {
	      $scope.invoice.invoice_items_attributes.splice(index, 1)
	      $scope.Calculation();
	    }
	    //Add Product row

	    $scope.addProduct = function () {
	      $scope.invoice.invoice_items_attributes.push({
	        item_id: '',
	        item_type: 'Product',
	        unit_price: '',
	        quantity: '',
	        tax: '',
	        discount: '',
	        total_price: '',
	        tax_amount: '',
	        discount_type_percentage: ''
	      })
	    }
	    $scope.Calculation = function () {
	      //modal parameters
	      $scope.CalculateTax = 0;
	      $scope.invoice.total_discount = 0;
	      $scope.invoice.subtotal = 0;
	      $scope.invoice.tax = 0;
	      $scope.invoice.invoice_amount = 0;
	      for (var i = 0; i < $scope.invoice.invoice_items_attributes.length; i++) {
	        if ($scope.invoice.invoice_items_attributes[i].total_price != '') {
	          if ($scope.invoice.invoice_items_attributes[i].tax != 'N/A') {
	            if ($scope.invoice.invoice_items_attributes[i].discount != undefined && $scope.invoice.invoice_items_attributes[i].discount != '') {
	              if ($scope.invoice.invoice_items_attributes[i].discount_type_percentage != '$') {
	                $scope.Cal_unit_price = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	                $scope.Actualtax = (parseFloat($scope.Cal_unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
	                $scope.SubTot = parseFloat($scope.Cal_unit_price) + parseFloat($scope.Actualtax);
	                $scope.Cal_Disc = (parseFloat($scope.invoice.invoice_items_attributes[i].discount) * parseFloat($scope.SubTot)) / 100;
	                $scope.TotalPrice = parseFloat($scope.SubTot) - parseFloat($scope.Cal_Disc);
	                $scope.invoice.invoice_items_attributes[i].total_price = $scope.TotalPrice.toFixed(2);
	                $scope.Final_SubPrice = parseFloat($scope.TotalPrice) / (1 + parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount) / 100)
	                $scope.FInalTax = (parseFloat($scope.TotalPrice) - parseFloat($scope.Final_SubPrice));
	                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.Cal_Disc)).toFixed(2);
	                $scope.invoice.invoice_amount = (parseFloat($scope.invoice.invoice_amount) + parseFloat($scope.TotalPrice)).toFixed(2);
	                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Final_SubPrice)).toFixed(2);
	                $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.FInalTax)).toFixed(2);
	              } 
	              else {
	                $scope.Cal_unit_price = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	                $scope.Actualtax = (parseFloat($scope.Cal_unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
	                $scope.SubTot = parseFloat($scope.Cal_unit_price) + parseFloat($scope.Actualtax);
	                $scope.Cal_Disc = parseFloat($scope.invoice.invoice_items_attributes[i].discount);
	                $scope.TotalPrice = parseFloat($scope.SubTot) - parseFloat($scope.Cal_Disc);
	                $scope.invoice.invoice_items_attributes[i].total_price = $scope.TotalPrice.toFixed(2);
	                $scope.Final_SubPrice = parseFloat($scope.TotalPrice) / (1 + parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount) / 100)
	                $scope.FInalTax = (parseFloat($scope.TotalPrice) - parseFloat($scope.Final_SubPrice));
	                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.Cal_Disc)).toFixed(2);
	                $scope.invoice.invoice_amount = (parseFloat($scope.invoice.invoice_amount) + parseFloat($scope.TotalPrice)).toFixed(2);
	                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Final_SubPrice)).toFixed(2);
	                $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.FInalTax)).toFixed(2);
	              }
	            } 
	            else { $scope.Cal_unit_price = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
                    $scope.Actualtax = (parseFloat($scope.Cal_unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
	              $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
	              $scope.Caltax = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	              $scope.Actualtax = (parseFloat($scope.Caltax) * parseFloat($scope.invoice.invoice_items_attributes[i].tax_amount)) / 100;
	              $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + parseFloat($scope.Caltax)).toFixed(2);
	              $scope.invoice.tax = (parseFloat($scope.invoice.tax) + parseFloat($scope.Actualtax)).toFixed(2);
	              $scope.totprice = parseFloat($scope.invoice.tax) + parseFloat($scope.invoice.subtotal);
	              $scope.invoice.invoice_amount = parseFloat($scope.totprice);
	              $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	              $scope.invoice.invoice_items_attributes[i].total_price = ($scope.Actualtax + $scope.totalpri).toFixed(2);
	              $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
	              $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
	              $scope.invoice.tax = parseFloat($scope.invoice.tax);
	              $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
	            }
	          } 
	          else {
	            if ($scope.invoice.invoice_items_attributes[i].discount != undefined && $scope.invoice.invoice_items_attributes[i].discount != '') {
	              if ($scope.invoice.invoice_items_attributes[i].discount_type_percentage != '$') {
	                $scope.Caldiscount = parseFloat($scope.invoice.invoice_items_attributes[i].discount) * parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
	                $scope.ActualDiscount = (parseFloat($scope.Caldiscount) / 100);
	                $scope.discount_type_percentagel = parseFloat($scope.ActualDiscount) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	                $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.discount_type_percentagel)).toFixed(2);
	                $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price) - parseFloat($scope.ActualDiscount);
	                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity))).toFixed(2);
	                $scope.totprice = (parseFloat($scope.invoice.subtotal));
	                $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
	                $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	                $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
	                $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
	                $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
	                $scope.invoice.tax = parseFloat($scope.invoice.tax);
	                $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
	              } 
	              else {
                  $scope.invoice.total_discount_temp = parseFloat($scope.invoice.invoice_items_attributes[i].discount).toFixed(2);
	                $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
	                $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity) - parseFloat($scope.invoice.total_discount_temp))).toFixed(2);
	                $scope.totprice = (parseFloat($scope.invoice.subtotal));
	                $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
	                $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity) - parseFloat($scope.invoice.total_discount_temp);
	                $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
                  $scope.invoice.total_discount = (parseFloat($scope.invoice.total_discount) + parseFloat($scope.invoice.total_discount_temp)).toFixed(2);
	                $scope.invoice.total_discount =  parseFloat($scope.invoice.total_discount);
	                $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
	                $scope.invoice.tax = parseFloat($scope.invoice.tax);
	                $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
	              }
	            } 
	            else {
	              $scope.SubTot = parseFloat($scope.invoice.invoice_items_attributes[i].unit_price);
	              $scope.invoice.subtotal = (parseFloat($scope.invoice.subtotal) + (parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity))).toFixed(2);
	              $scope.totprice = parseFloat($scope.invoice.subtotal);
	              $scope.invoice.invoice_amount = (parseFloat($scope.totprice) + parseFloat($scope.invoice.tax)).toFixed(2);
	              $scope.totalpri = parseFloat($scope.SubTot) * parseFloat($scope.invoice.invoice_items_attributes[i].quantity);
	              $scope.invoice.invoice_items_attributes[i].total_price = $scope.totalpri.toFixed(2);
	              $scope.invoice.total_discount = parseFloat($scope.invoice.total_discount);
	              $scope.invoice.subtotal = parseFloat($scope.invoice.subtotal);
	              $scope.invoice.tax = parseFloat($scope.invoice.tax);
	              $scope.invoice.invoice_amount = parseFloat($scope.invoice.invoice_amount);
	            }
	          }
	        }
	      }
	    }
	    $scope.today = function () {
	      $scope.dt = new Date();
	    };
	    $scope.today();
	    $scope.clear = function () {
	      $scope.dt = null;
	    };
	    $scope.open = function ($event) {
	      $scope.status.opened = true;
	    };
	    $scope.status = {
	      opened: false
	    };
	    //$scope.Calculation();

	    $scope.CreateInvoice = function (data, flag) {
        if (flag == true) {
            $scope.flag = true

        } else{
            $scope.flag = false
        }
        data.issue_date = new Date(data.issue_date);
        var new_Date_month = data.issue_date.getMonth() + 1;
        var new_Date_day = data.issue_date.getDate();
        if (new_Date_month < 10)
          new_Date_month = '0' + new_Date_month;
        if (new_Date_day < 10)
          new_Date_day = '0' + new_Date_day;
        data.issue_date = data.issue_date.getFullYear() + '-' + new_Date_month + '-' + new_Date_day;
            if( typeof data.patient === 'string' ) {
                $rootScope.cloading = false;
                $rootScope.showErrorToast('Patient is not Valid');
            }
            else {
                $rootScope.cloading = true;
                $http.put(' /invoices/' + $stateParams.invoice_id, {
                    invoice: data,
                    flag: $scope.flag
                }).success(function (results) {
                    if (results.error) {
                        $rootScope.cloading = false;
                        $rootScope.errors = results.error;
                        $rootScope.showMultyErrorToast();
                    }else if(results.flag == false){
                        $rootScope.cloading = false;
                        $rootScope.showErrorToast('Patient is not Valid');
                    }
                    else {
                        var promise = $scope.invoiceLogs($scope.paging);
                        promise.then(function(greeting) {
                            $translate('toast.invoiceAddedd').then(function (msg) {
                                $rootScope.showSimpleToast(msg);
                            });
                        });
                        if ($rootScope.credit_balance >= (localStorage.getItem('inv_sub_total') - data.subtotal) && $scope.flag == true) {
                            if ($stateParams.app_id)
                              $state.go('appointment.invoiceView', { 'invoice_id':$stateParams.invoice_id});
                            else if ($state.current.name == 'appointment.invoiceView')
                              $state.go('appointment');
                            else
                              $state.go('patient-detail', { 'patient_id':data.patient.id}, { reload: true });
                        } else if (localStorage.getItem('inv_sub_total') > data.subtotal) {
                            $state.go('patient-detail', { 'patient_id':data.patient.id}, { reload: true });
                        } else{
                            // var promise = $scope.GetInvoice();
                            var promise = $scope.invoiceLogs($scope.paging);
                            promise.then(function(greeting){
                                $translate('toast.invoiceAddedd').then(function (msg) {
                                    $rootScope.showSimpleToast(msg);
                                });

                                $scope.noData = false;
                                $rootScope.cloading = false;
                                $rootScope.InvoiceList = $rootScope.InvoiceList;

                                if ($stateParams.patient_id) {
                                  $state.go('patient-detail.invoicePayment', {
                                      'invoice_id': results.id
                                  }, {reload: true});
                                  $rootScope.filterClientFiles($rootScope.ChkData);
                                  $rootScope.CountClientFile();
                                }
                                else if ($stateParams.app_id) {
                                    $rootScope.getEvents();
                                    $state.go('appointment.newPayment', {
                                        'invoice_id': results.id
                                    });
                                } else {
                                     //$scope.GetInvoice();
                                    if ($scope.InvoiceDetails.invoice_amount >= data.invoice_amount) {
                                      $state.go('invoice');
                                    } else {
                                      $scope.invoiceLogs($scope.paging);
                                      $state.go('invoice.newPayment', {
                                          'invoice_id': results.id
                                      });
                                      //$state.go('patient-detail', { 'patient_id':data.patient.id});
                                    }
                                }
                            });
                        }
                    }
                }).error(function (status) {
                    $state.go('error');
                });
            }

	    }
    }
    $timeout(function () {
      $scope.GetPractionerDetails($scope.invoice.practitioner, $scope.invoice.business)
    }, 2000);
    
  }
]);
/*app.controller('InvoiceListCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$filter',
  'lazyload',
  '$stateParams',
  '$timeout',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $filter, lazyload, $stateParams, $timeout) {
    $rootScope.GetInvoice = function () {
      Data.get('/invoices').then(function (results) {
        $scope.total_invoices = 0;
        $scope.total_outstanding = 0;
        $rootScope.InvoiceList = results;
        if ($rootScope.InvoiceList.invoices.length == 0) {
          $scope.noModule = true;
          $scope.noData = true;
        }
        $scope.pagging = [
        ];
        for (i = 1; i <= $rootScope.InvoiceList.pagination.total_pages; i++) {
          $scope.pagging.push({
            pageNo: i
          });
        }
      });
    }
    $rootScope.GetInvoice();
    //pagination code---------------------------------------------------
    //next page
    $scope.hitNext = function () {
      $rootScope.cloading = true;
      $http.get($rootScope.InvoiceList.pagination.next_url).success(function (data) {
        $rootScope.InvoiceList = data;
        $rootScope.cloading = false;
      });
    }
    //previous page

    $scope.hitPrev = function () {
      $rootScope.cloading = true;
      $http.get($rootScope.InvoiceList.pagination.previous_url).success(function (data) {
        $rootScope.InvoiceList = data;
        $rootScope.cloading = false;
      });
    }
    //next page URL

    $scope.nextPage = function (pageNo) {
      $rootScope.cloading = true;
      if (pageNo == 1) {
        $http.get('/invoices').success(function (data) {
          $rootScope.InvoiceList = data;
          $rootScope.cloading = false;
        });
      } 
      else {
        $http.get('/invoices?page=' + pageNo).success(function (data) {
          $rootScope.InvoiceList = data;
          $rootScope.cloading = false;
        });
      }
    }
    //pagination ends here----------------------------------------------------  
    //filter for invoice search list

    $scope.noRecordFount = false;
    var _timeout;
    $scope.invoiceSearch = function (Term) {
      if (_timeout) { //if there is already a timeout in process cancel it
        $timeout.cancel(_timeout);
      }
      _timeout = $timeout(function () {
        $rootScope.cloading = true;
        $http.get('/invoices?q=' + Term).success(function (data) {
          $rootScope.InvoiceList = data;
          if ($rootScope.InvoiceList.invoices.length == 0) {
            $scope.noRecordFount = true;
            $scope.noModule = false;
          } 
          else {
            $scope.noRecordFount = false;
          }
          $rootScope.cloading = false;
        });
        _timeout = null;
      }, 1000);
    }
  }
]);*/

app.factory('checkNumber', function() {
   var checkNumber1 = {};
   checkNumber1.checkNumb = function(args){
     if(!isNaN(args)){
      return args
     }
     else{
      return 'Error'
     }
    }
   return checkNumber1;
});
app.controller('InvoiceEditCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$modal',
  '$stateParams',
  'checkNumber',
  '$translate',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $modal, $stateParams, checkNumber, $translate) {
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
          //alert(data.invoice.subtotal);
          //localStorage.setItem('inv_sub_total', data.invoice.subtotal);
        $scope.list_appointment = data.appointment_list;
        $scope.getBilable(data.invoice.patient.id);
        data.invoice.appointment = parseInt(data.invoice.appointment);
        $scope.invoice = data.invoice;
        $scope.initialInvoice = angular.copy($scope.invoice)
        $scope.GetPatientDetails(data.invoice.patient.id);
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
    //Patient Details in patientId
    /*$scope.GetPatientDetails = function (value) {
      if (value.id != null && value.id != '' && value.id != $scope.initialInvoice.patient.id)
      {
        $http.get('/patient_details/' + value.id).success(function (list) {
          $scope.invoice.invoice_to = list.patient.invoice_to;
          $scope.invoice.extra_patient_info = list.patient.invoice_extra_info;
          $scope.patientIds = value.id;
          //$rootScope.getBilable();
        });
      }
    }*/

    /*$scope.GetPatientDetails = function (value) {
      $scope.current_patient_id = value.id;
      if (value != undefined)
      {
        $http.get('/appointments/' + value.id + '/' + $scope.first_practioner + '?bs=' + $scope.invoice.business).success(function (list) {
          $scope.patient = list;
          if (list.appointment.length) {
            $scope.invoice.type_appointment = 'Appointment';
          }
          else if (list.appointment_type.length) {
            $scope.invoice.type_appointment = 'AppointmentType';
          }
          if(!$stateParams.app_id){
            $scope.invoice.appointment = '';
          }
          $scope.invoice.invoice_to = list.patient.invoice_to;
          $scope.invoice.extra_patient_info = list.patient.invoice_extra_info;
          $scope.patientIds = value.id;
          $rootScope.getBilable();
        });
      }
    }*/


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




    //Patient Details in patientId
    //$scope.invoice.appointment = '';

    //get invoice Detail
    $scope.country = '';
    $scope.invoiceDetail = function (id) {
      $rootScope.cloading = true;
      $http.get('/invoices/' + id).success(function (result) {
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
      });
    }
    $scope.invoiceDetail($stateParams.invoice_id);


    //get Appointments details

    $scope.getAppointmentDetails = function (id) {
      if (id) {
        $http.get('/invoice/appointment_types/' + $scope.invoice.patient.id + '/' + id).success(function (results) {
          $scope.invoice.invoice_items_attributes.length = 0;
          $scope.appointmentData = results;
          $scope.appointmentData.billable_items.forEach(function (bilable_items) {
            bilable_items.item_id = '' + bilable_items.item_id;
            bilable_items.item_type = 'BillableItem';
            $scope.invoice.invoice_items_attributes.push(bilable_items)
          });
          $scope.appointmentData.products.forEach(function (products) {
            products.item_id = '' + products.item_id;
            products.item_type = 'Product'
            $scope.invoice.invoice_items_attributes.push(products)
          });
          $scope.Calculation();
        });
      }
    }
    //get AppointmentsType details

    $scope.getAppointmentTypeDetails = function (data) {
      $scope.AppointmenttypeID = data.appointment_type_id;
      var data = JSON.parse(data);
      var id = angular.copy(data.appointment_type_id);
      //$scope.invoice.appointment = data.appointment_id;
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
        data.forEach(function(patient){
          patient.fullName = patient.first_name+' '+patient.last_name;
        })
        $scope.PatientListData = data;
      });
    }
    $scope.getPatientsData();
    //Get Bussiness List
    $rootScope.GetBussiness = function () {
      Data.get('/list/businesses').then(function (results) {
        $scope.BussinessList = results;
      });
    }
    $rootScope.GetBussiness();
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
            if (p.concession == true)
            {
              $scope.Concession_Name = 'Discount Type: ' + p.concession_name;
              $scope.invoice.invoice_items_attributes.concession_id = p.concession_id
            }
            else
            {
              $scope.Concession_Name = '';
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

    $scope.CreateInvoice = function (data) {
      data.issue_date = new Date(data.issue_date);
      var new_Date_month = data.issue_date.getMonth() + 1;
      var new_Date_day = data.issue_date.getDate();
      if (new_Date_month < 10)
        new_Date_month = '0' + new_Date_month;
      if (new_Date_day < 10)
        new_Date_day = '0' + new_Date_day;
      data.issue_date = data.issue_date.getFullYear() + '-' + new_Date_month + '-' + new_Date_day;
      $rootScope.cloading = true;
      $http.put(' /invoices/' + $stateParams.invoice_id, {
        invoice: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        }
        else {
          $rootScope.cloading = false;
          $translate('toast.invoiceUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
          if ($stateParams.patient_id) {
            $state.go('patient-detail',{"patient_id" : $stateParams.patient_id}, {reload: true});
            $rootScope.filterClientFiles($rootScope.ChkData);
            $rootScope.CountClientFile();
          }
          else if($state.includes('appointment')){
            $state.go('appointment.newPayment', {
              'invoice_id': results.id
            });
          }
          else{
            $state.go('invoice');
          }
        }
      }).error(function (status) {
        $state.go('error');
      });
    }
  }
]);

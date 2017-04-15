app.controller('PaymentEditCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$stateParams',
  '$translate',
  '$modal',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $stateParams, $translate, $modal) {
    $scope.header = {
      module:'controllerVeriable.payment',
      title:'Summary',
      back_link: 'payment',
    }
    if ($stateParams.patient_id) {
      $scope.header.back_link = 'patient-detail({"patient_id" : ' + $stateParams.patient_id + '})'
    }
    else if ($state.includes('invoice')) {
      $scope.header.back_link = 'invoice';
    }
    else if ($state.includes('appointment')) {
      $scope.header.back_link = 'appointment';
    }
    if ($state.includes('paymentEdit')) {
      $scope.header.title = 'controllerVeriable.editPayment';
    }
    $scope.editPayment = true;
    $scope.editPaymentForm = false;
    $scope.doEditPayment = function(){
      $scope.editPaymentForm = true;
      $scope.header.title = 'controllerVeriable.editPayment';
    }
    $scope.Payment = {};
    $scope.open = function ($event) {
      $scope.status.opened = true;
    };
    $scope.status = {
      opened: false
    };
    $scope.AmountPaid = 0;
    //initial camculation
    $scope.initial_calculation = function () {
      $scope.Outstandings = 0;
      $scope.PaymentApplied = 0;
      $scope.AmountPaid = 0;
      $scope.Totalremaining = 0;
      if ($scope.ApplyInvoicesData) {
        $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
          $scope.Outstandings = parseFloat(parseFloat(invoice.amount_outstanding) + parseFloat($scope.Outstandings)).toFixed(2);
          $scope.PaymentApplied = parseFloat(parseFloat(invoice.amount) + parseFloat($scope.PaymentApplied)).toFixed(2);
          $scope.Totalremaining = parseFloat(parseFloat(invoice.amount_remaining) + parseFloat($scope.Totalremaining)).toFixed(2)
        });
      }
      if ($scope.Payment.payment_types_payments_attributes) {
        $scope.Payment.payment_types_payments_attributes.forEach(function (obj) {
          if (obj.amount != undefined && obj.amount != '')
          {
            obj.amount = parseFloat(obj.amount);
            $scope.AmountPaid = (parseFloat(obj.amount + parseFloat($scope.AmountPaid))).toFixed(2);
          }
        })
      }
      if ($scope.PaymentApplied > $scope.AmountPaid) {
        $scope.unallocated = true;
        $scope.UnallocatedCredit = (parseFloat(parseFloat($scope.AmountPaid) - $scope.PaymentApplied)).toFixed(2);
      } 
      else if ($scope.PaymentApplied == $scope.AmountPaid) {
        $scope.unallocated = false;
      } 
      else {
        $scope.unallocated = true;
        $scope.UnallocatedCredit = (parseFloat(parseFloat($scope.AmountPaid) - $scope.PaymentApplied)).toFixed(2);
      }
      $scope.getPatientsData();
    }
    $scope.getPatientsData = function () {
      $http.get('/list/patients').success(function (data) {
        data.forEach(function(patient){
          patient.fullName = patient.first_name+' '+patient.last_name;
        })
        $scope.PatientListData = data;
        if ($scope.current_patient != undefined) {
          $scope.filterPatient = $filter('filter') (data, $scope.current_patient);
          $scope.Payment.patient = {
            first_name: $scope.filterPatient[0].first_name,
            last_name: $scope.filterPatient[0].last_name,
            id: $scope.filterPatient[0].id
          }
        }
      });
    }
    $scope.formatLabel = function(value){
      if(!value){
        return;
      }
      return value.first_name +' '+value.last_name; 
    }
    //calculate payments
    $scope.showRemaining=true;
    $scope.CalAmount = function () {
      $scope.AmountPaid = 0;
      $scope.Totalremaining = 0;
      $scope.Outstandings = 0;
      $scope.PaymentApplied = 0;
      if ($scope.Payment.payment_types_payments_attributes) {
        $scope.Payment.payment_types_payments_attributes.forEach(function (obj) {
          if (obj.amount != undefined && obj.amount != '')
          {
            obj.amount = parseFloat(obj.amount);
            $scope.AmountPaid = (parseFloat(obj.amount + parseFloat($scope.AmountPaid))).toFixed(2);
          }
        })
        if ($scope.ApplyInvoicesData) {
          var totalPaymentinvoice = angular.copy($scope.AmountPaid);
          $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
            /*invoice calculation*/
            invoice.Credit_Amount = 0;
            $scope.unallocated = false;
            if (totalPaymentinvoice > invoice.amount_outstanding) {
              invoice.amount = parseFloat(invoice.amount_outstanding);
              totalPaymentinvoice = parseFloat(totalPaymentinvoice - invoice.amount_outstanding)
            } 
            else if (totalPaymentinvoice <= invoice.amount_outstanding) {
              invoice.amount = parseFloat(totalPaymentinvoice);
              totalPaymentinvoice = 0;
            }
            invoice.amount_remaining = invoice.amount_outstanding - invoice.amount;
            $scope.Totalremaining = parseFloat($scope.Totalremaining + invoice.amount_remaining)
            $scope.PaymentApplied = parseFloat(invoice.amount + $scope.PaymentApplied);
            /*if unallocated amount*/
            if (totalPaymentinvoice > 0) {
              $scope.unallocated = true;
              $scope.UnallocatedCredit = (parseFloat(totalPaymentinvoice)).toFixed(2);
              /*$scope.patient.credit_account=parseFloat($scope.UnallocatedCredit);*/
            }
            $scope.Outstandings = parseFloat(invoice.amount_outstanding + $scope.Outstandings);
          })
        }
      }
      $scope.CalculateCredit();
      
    }
    //calculate credits

    $scope.CalculateCredit = function () {
      if ($rootScope.CreditAmount > 0) {
        $scope.TotalPayment = 0;
        $scope.Totalremaining = 0;
        $scope.CreditApplied = 0;
        $scope.TotalPayment = $rootScope.CreditAmount;
        if ($scope.ApplyInvoicesData) {
          var totalPaymentinvoice = angular.copy($scope.TotalPayment);
          $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
            invoice.Credit_Amount = 0;
            //$scope.unallocated = false;
            if ($scope.PaymentApplied < 0) {
              invoice.amount_remaining = invoice.amount_outstanding;
            }
            if (totalPaymentinvoice > invoice.amount_remaining) {
              invoice.credit_amount = parseFloat(invoice.amount_remaining);
              totalPaymentinvoice = parseFloat(totalPaymentinvoice - invoice.amount_remaining);
            } 
            else if (totalPaymentinvoice <= invoice.amount_remaining) {
              invoice.credit_amount = parseFloat(totalPaymentinvoice);
              totalPaymentinvoice = 0;
            }
            invoice.amount_remaining = invoice.amount_remaining - invoice.credit_amount;
            $scope.Totalremaining = parseFloat($scope.Totalremaining + invoice.amount_remaining)
            if(isNaN($scope.Totalremaining)){
              $scope.Totalremaining='Error';
              $scope.showRemaining=false;
            }
            else{
              $scope.showRemaining=true;
            }
            $scope.CreditApplied = parseFloat(invoice.credit_amount + $scope.CreditApplied);
            if (totalPaymentinvoice > 0) {
              //$scope.unallocated = true;
              //$scope.UnallocatedCredit=parseFloat(totalPaymentinvoice);
            }
            if (!$scope.Payment.payment_types_payments_attributes) {
              $scope.Outstandings = parseFloat(invoice.amount_outstanding + $scope.Outstandings);
            }
          });
        }
      }
    }
    //calculate payments again

    $scope.CalPayments = function (index)
    {
      $scope.PaymentAmount = 0;
      $scope.PaymentApplied = 0;
      var invoice = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list[index];
      if (invoice.amount == '')
      {
        invoice.amount = 0;
      }
      invoice.amount_remaining = parseFloat(invoice.amount_outstanding - invoice.amount);
      $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
        $scope.PaymentApplied = parseFloat(parseFloat(invoice.amount) + $scope.PaymentApplied);
        if ($scope.PaymentApplied > $scope.AmountPaid) {
          $scope.unallocated = true;
          $scope.UnallocatedCredit = parseFloat(parseFloat($scope.AmountPaid) - $scope.PaymentApplied);
        } 
        else if ($scope.PaymentApplied == $scope.AmountPaid) {
          $scope.unallocated = false;
        } 
        else {
          $scope.unallocated = true;
          $scope.UnallocatedCredit = parseFloat(parseFloat($scope.AmountPaid) - $scope.PaymentApplied);
          ;
        }
      })
      if (invoice.amount_remaining < 0) {
        invoice.amount_remaining = 0;
      }
      $scope.CalculateCredit();
    }
    //calculate credits again

    $scope.CalCredits = function (index) {
      $scope.CreditApplied = 0;
      $scope.Totalremaining = 0;
      var invoice = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list[index];
      if (invoice.Credit_Amount == '' && invoice.Credit_Amount == 0)
      {
        invoice.Credit_Amount = 0;
      }
      invoice.amount_remaining = parseFloat(invoice.amount_outstanding - (parseFloat(invoice.Credit_Amount) + parseFloat(invoice.amount)));
      if (invoice.amount_remaining < 0) {
        invoice.amount_remaining = 0;

      }
      $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
        $scope.CreditApplied = parseFloat(parseFloat(invoice.Credit_Amount) + $scope.CreditApplied);
        $scope.Totalremaining = parseFloat($scope.Totalremaining + invoice.amount_remaining)
        if(isNaN($scope.Totalremaining)){
          $scope.Totalremaining='Error';
          $scope.showRemaining=false;
        }
        else{
          $scope.showRemaining=true;
        }
      })
    }
    $scope.GetBussiness = function () {
      $http.get('/list/businesses').success(function (results) {
        $scope.BussinessList = results;
        $scope.Payment.business=$scope.BussinessList[0];
      });
    }
    $scope.GetBussiness();
    //Add Payment Type

    $scope.AddPayment = function () {
      $scope.Payment.payment_types_payments_attributes.push({
        payment_type_id: '',
        amount: ''
      })
    }
    //Remove Payment type 

    $scope.RemovePaymentType = function (index) {
      $scope.Payment.payment_types_payments_attributes.splice(index, 1)
      $scope.CalAmount();
    }
    //Get Invoice Details

    $scope.PatientID = parseInt($scope.PatientID);
    $scope.GetInvoiceDetails = function (value)
    {
      if (value) {
        $http.get('/patient/' + value.id + '/' + $stateParams.payment_id + '/invoices').success(function (data) {
          $scope.ApplyInvoicesData = data;
          $scope.Payment.invoices_payments_attributes = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list;
          $rootScope.CreditAmount = $scope.ApplyInvoicesData.rest_invoices.credit_account;
          $scope.initial_calculation();
          $scope.CalAmount();
        });
      }
    }
    //Get Payment type

    $scope.getpaymentList = function () {
      $rootScope.cloading = true;
      //Get PaymentList
      Data.get('/payment/payment_types').then(function (list) {
        $rootScope.paymentList = list;
        $rootScope.cloading = false;
      });
    }
    $scope.getpaymentList();

    $scope.getDetailPayment = function (id) {
      $rootScope.cloading = true;
      $http.get('/payments/' + id).success(function (result) {
        $scope.PaymentDetails = result.payment;
        $rootScope.cloading = false;
      });
    }
    $scope.getDetailPayment($stateParams.payment_id);
    //email account statement to patient's email
    $scope.emailPatient = function (id) {
      $rootScope.cloading = true;
      $http.get('/invoices/' + id + '/send_email?email_to=patient').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      });
    }
    //print invoice
    $scope.printInvoice = function (id) {
      var win = window.open('/invoices/' + id + '/print.pdf', '_blank');
      win.focus();
    }
    //print payment
    $scope.PrintPayment = function (id) {
      var win = window.open('/payments/' + id + '/print.pdf', '_blank');
      win.focus();
    }
    //Delete Payment
    $scope.PaymentDelete = function (size, id, events) {
      $scope.Payment_ID = id;
      $scope.Payment_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };

    $rootScope.okdelete = function () {
      $rootScope.modalInstance.close($scope.DeletePayment($scope.Payment_ID, $scope.Payment_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $scope.DeletePayment = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/payments/' + id).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          if ($stateParams.patient_id) {
            $state.go('patient-detail',{"patient_id" : $stateParams.patient_id});
            $rootScope.filterClientFiles($rootScope.ChkData);
            $rootScope.CountClientFile();
          }
          else{
            $state.go('payment')
          }
          $translate('toast.paymentDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }

    //GetPaymentDetails
    $scope.GetPaymentDetails = function () {
      $http.get('/payments/' + $stateParams.payment_id + '/edit').success(function (data) {
        if (!data.code) {
          $scope.Payment = data.payment;
          $scope.Payment.payment_hr = '' + $scope.Payment.payment_hr;
          $scope.Payment.payment_min = '' + $scope.Payment.payment_min;
          /*$scope.Payment.payment_types_payments_attributes.forEach(function(pay){
            pay.payment_type_id = '' + pay.payment_type_id;
          })*/
          $scope.Payment.business = parseInt($scope.Payment.business);
          //$scope.Payment.business=$scope.BussinessList[0];
          /*$scope.BussinessList.forEach(function(bus){
            if(bus.id == $scope.Payment.business.id){
              $scope.Payment.business.$$hashKey = bus.$$hashKey;
            }
          })*/
          $scope.GetInvoiceDetails($scope.Payment.patient);
        }
        else{
          $scope.Payment = data;
        }
                       
      });
    }
    $scope.GetPaymentDetails();
    //Update Payment
    $scope.CreatePayment = function (Payment) {
      Payment.payment_date = new Date(Payment.payment_date);
      var new_Date_month = Payment.payment_date.getMonth() + 1;
      var new_Date_day = Payment.payment_date.getDate();
      if (new_Date_month < 10)
        new_Date_month = '0' + new_Date_month;
      if (new_Date_day < 10)
        new_Date_day = '0' + new_Date_day;
      Payment.payment_date = Payment.payment_date.getFullYear() + '-' + new_Date_month + '-' + new_Date_day;
      $rootScope.cloading = true;
      $http.put('/payments/' + $stateParams.payment_id, {
        payment: Payment
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          if (!$stateParams.patient_id && !$state.includes('invoice') && !$state.includes('appointment')) {
            // $scope.$parent.PaymentListData();
            $state.go('payment', {}, {reload: true});
          }
          else if($state.includes('invoice')){
            $state.go('invoice');
          }
          else if($state.includes('appointment')){
            $rootScope.getEvents();
            $state.go('appointment.invoiceView', {
              'invoice_id': $state.params.invoice_id
            }); 
          }          
          else if ($stateParams.patient_id) {
            $state.go('patient-detail',{"patient_id" : $stateParams.patient_id}, {reload: true});
            $rootScope.filterClientFiles($rootScope.ChkData);
            $rootScope.CountClientFile();
          }
          else{
            $state.go('payment');
          }
          $translate('toast.paymentUpdated').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
        }
      });
    }
  }
]);

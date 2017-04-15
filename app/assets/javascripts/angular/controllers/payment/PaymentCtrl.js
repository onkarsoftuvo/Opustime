app.controller('PaymentCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$timeout',
  '$translate',
  '$window',
  '$stateParams',
  'pageService',
  function ($rootScope, $scope, $state, $http, $modal, $timeout, $translate, $window, $stateParams, pageService) {

    init();

    function init(){
      $scope.pagingData = {};
      $scope.pagingData.fromFilter = '',
      $scope.pagingData.toFilter = '',
      $scope.pagingData.Page = 1;
      $scope.pagingData.TotalItems = 0;
      $scope.pagingData.PageSize = 30;
      $scope.showGrid = false;
    }


    //get all permissions
    function getPermissions(){
      $http.get('/payments/security_roles').success(function(data){
        console.log(data);
        $rootScope.payPerm = data;

        if (!data.create && $window.location.hash == '#!/payment/new' || $window.location.hash == '#!/patient-detail/'+$stateParams.patient_id+'/newPayment') {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard')
        }
        else{
          
        }
        if (!data.view) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard')
        }
        else{
          $scope.paymentLogs($scope.pagingData);
        }
      });
    }
    getPermissions();

    //get payment list
    $scope.paymentLogs = function(pagingData) {
      $scope.PaymentList = [];
      // obj = $http.get('/sms_center/logs');
      if(pagingData.fromFilter == "") {
        obj = $http.get('/payments?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }else{
        obj = $http.get('/payments?q=' + pagingData.fromFilter + '&per_page=' + pagingData.PageSize + '&page=' + pagingData.Page);
      }
      obj.success(function(data){
        if(data.payment.length != 0){
          for (var i = 0; i < data.payment.length; i++) {
            data.payment[i].isopen = false;
          }
          $scope.PaymentList = data.payment;
          $scope.PaymentDetail = data;
          $scope.pagingData.TotalItems = data.total;
          $scope.noRecordFount = false;
          $scope.showGrid = true;
          setPager();
        }else{
          $scope.noRecordFount = true;
          $scope.showGrid = false;
        }
      });
    }


    //pagination code---------------------------------------------------
   
    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.paymentLogs($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };

    //pagination ends here----------------------------------------------------  

    //Clear payment logs
    $scope.clearLogs = function() {
      $scope.pagingData.fromFilter = "";
      $scope.paymentLogs($scope.pagingData);
    }

    //filter for payment search list
    // $scope.noRecordFount = false;
    // var _timeout;
    // $scope.paymentSearch = function (Term) {
    //   if (_timeout) { //if there is already a timeout in process cancel it
    //     $timeout.cancel(_timeout);
    //   }
    //   _timeout = $timeout(function () {
    //     $rootScope.cloading = true;
    //     $http.get('/payments?q=' + Term).success(function (data) {
    //       $scope.PaymentList = data;
    //       $rootScope.cloading = false;
    //       if ($scope.PaymentList.payment.length == 0) {
    //         $scope.noRecordFount = true;
    //         $scope.noModule = false;
    //       } 
    //       else {
    //         $scope.noRecordFount = false;
    //       }
    //     });
    //     _timeout = null;
    //   }, 1000);
    // }
    
    $scope.editPaymentDetail = function(id){
      $state.go('payment.edit', {payment_id : id});
    }
    //Delete Payment
    $scope.PaymentDelete = function (size, id, events) {
      $rootScope.Payment_ID = id;
      $rootScope.Payment_events = events;
      events.preventDefault();
      events.stopPropagation();
      $rootScope.modalInstance = $modal.open({
        animation: $scope.animationsEnabled,
        templateUrl: 'DeleteModal.html',
        size: size,
      });
    };
    $rootScope.deleteConfirm = function () {
      $rootScope.modalInstance.close($rootScope.DeletePayment($rootScope.Payment_ID, $rootScope.Payment_events));
    };
    $rootScope.cancel = function () {
      $rootScope.modalInstance.dismiss('cancel');
    };
    $rootScope.DeletePayment = function (id, e) {
      e.preventDefault();
      e.stopPropagation();
      $rootScope.cloading = true;
      $http.delete ('/payments/' + id).success(function (results) {
        console.log('deleting payment method is calling ========> ' , results);
        $scope.paymentLogs($scope.pagingData);
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $translate('toast.paymentDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
      });
    }
  }
]);

app.controller('PaymentNewCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$state',
  '$http',
  'filterFilter',
  '$stateParams',
  '$filter',
  '$translate',
  function ($rootScope, $scope, Data, $state, $http, filterFilter, $stateParams, $filter, $translate) {
    $scope.Payment = {
      payment_types_payments_attributes: [
        {
          payment_type_id: '',
          amount: ''
        }
      ]
    };
    $scope.editPayment = false;
    $scope.editPaymentForm = true;
    $scope.header = {
      module:'controllerVeriable.payment',
      title:'controllerVeriable.newPayment',
      back_link: 'payment',
    }
    if ($stateParams.patient_id) {
      $scope.header.back_link = 'patient-detail({"patient_id" : ' + $stateParams.patient_id + '})'
    }
    else if ($stateParams.invoice_id) {
      if ($state.includes('appointment')) {
        $scope.header.back_link = 'appointment';
      }
      else{
        $scope.header.back_link = 'invoice';
      }
    }

      //Get Invoice Details

      $scope.PatientID = parseInt($scope.PatientID);
      $scope.GetInvoiceDetails = function (value)
      {
          $scope.paymentId = 'new';
          if (value) {
              $http.get('/patient/' + value.id + '/' + $scope.paymentId + '/invoices').success(function (data) {
                  $scope.ApplyInvoicesData = data;
                  $rootScope.CreditAmount = $scope.ApplyInvoicesData.rest_invoices.credit_account;
                  $scope.Payment.payment_types_payments_attributes[0].payment_type_id = '' + data.default_payment_type_id
                  $scope.Payment.invoices_payments_attributes = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list;
                  $scope.CalAmount();
                  $scope.Payment.payment_types_payments_attributes[0].amount = $scope.Outstandings;
                  $scope.CalAmount();
              });
          }
      }

    //get invoice data
    $scope.getInvoiceData = function () {
      $scope.GetInvoiceDetails({id:$stateParams.patient_id});
      if ($state.params.invoice_id != undefined)
      {
        $scope.newInvoiceId = $state.params.invoice_id;
        $http.get('/invoice/' + $state.params.invoice_id + '/payments/new').success(function (data) {
          $scope.Payment = data.payment;
          $scope.Payment.payment_types_payments_attributes = [
            {
              payment_type_id: '',
              amount: ''
            }
          ];
          $scope.today();
          $scope.GetInvoiceDetails($scope.Payment.patient);
        });
      }
    }
    $scope.getInvoiceData();
    $scope.current_patient = $stateParams.patient_id;
    //Get Payment PaymentList
    $scope.getpaymentList = function () {
      $rootScope.cloading = true;
      Data.get('/payment/payment_types').then(function (list) {
        $scope.paymentList = list;
        $rootScope.cloading = false;
      });
    }
    $scope.getpaymentList();
    //Get patient data
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
    $scope.getPatientsData();
    $scope.PatientListDataf = function (query) {
      console.log(query)
      if(!query){
        return;
      }
      query = angular.lowercase(query)
      return $filter('filter') ($scope.PatientListData, query)
    }
    $scope.formatLabel = function(value){
      if(!value){
        return;
      }
      return value.first_name +' '+value.last_name; 
    }
    //Get Bussiness List

    $scope.GetBussiness = function () {
      Data.get('/list/businesses').then(function (results) {
        $scope.BussinessList = results;
        if (results.length == 1) {
          $scope.Payment.business = results[0].id;
        }
      });
    }
    $scope.GetBussiness();

    $scope.BussinessListf = function (query) {
      query = angular.lowercase(query)
      return $filter('filter') ($scope.BussinessList, query)
    }
    //Bind Datetime
    $scope.today = function () {
      $scope.Payment.payment_date = new Date();
      $scope.Payment.payment_hr = '' + ($scope.Payment.payment_date).getHours();
      $scope.Payment.payment_min = '' + ($scope.Payment.payment_date).getMinutes();
    };
    $scope.today();
    $scope.clear = function () {
    };
    $scope.open = function ($event) {
      $scope.status.opened = true;
    };
    $scope.status = {
      opened: false
    };
    //Add Payment Type
    $scope.AddPayment = function () {
      $scope.Payment.payment_types_payments_attributes.push({
        payment_type_id: '',
        amount: ''
      })
      $scope.CalAmount();
    }
    //Remove Payment type 

    $scope.RemovePaymentType = function (index) {
      $scope.Payment.payment_types_payments_attributes.splice(index, 1)
      $scope.CalAmount();
    }
    $scope.isdisabled = function (id) {
      var selectedPayment = filterFilter($scope.Payment.payment_types_payments_attributes, {
        payment_type_id: id
      });
      if (selectedPayment.length > 0) {
        return true;
      }
    }
    $scope.AmountPaid = 0;
    $scope.AmountPaid = 0;
    $scope.Totalremaining = 0;
    $scope.Outstandings = 0;
    $scope.PaymentApplied = 0;
    $scope.CreditApplied = 0;
    //calculate payments
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
            if ($scope.AmountPaid == 'NaN') {
              $scope.AmountPaid = 'Error';
            }
          }
        })
        if ($scope.ApplyInvoicesData) {
          var totalPaymentinvoice = parseFloat(angular.copy($scope.AmountPaid));
          $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
            /*invoice calculation*/
            invoice.credit_amount = 0;
            $scope.unallocated = false;
            if (totalPaymentinvoice > invoice.amount_outstanding) {
              invoice.amount = parseFloat(invoice.amount_outstanding);
              totalPaymentinvoice = parseFloat(totalPaymentinvoice - parseFloat(invoice.amount_outstanding));
            } 
            else if (totalPaymentinvoice <= invoice.amount_outstanding) {
              invoice.amount = parseFloat(totalPaymentinvoice);
              totalPaymentinvoice = 0;
            }
            invoice.amount_remaining = parseFloat(invoice.amount_outstanding) - parseFloat(invoice.amount);
            $scope.Totalremaining = (parseFloat($scope.Totalremaining + parseFloat(invoice.amount_remaining))).toFixed(2);
            $scope.PaymentApplied = (parseFloat(invoice.amount + parseFloat($scope.PaymentApplied))).toFixed(2);

            /*if unallocated amount*/
            if (totalPaymentinvoice > 0) {
              $scope.unallocated = true;
              $scope.UnallocatedCredit = parseFloat(totalPaymentinvoice).toFixed(2);
              /*$scope.patient.credit_account=parseFloat($scope.UnallocatedCredit);*/
            }
            $scope.Outstandings = parseFloat(parseFloat(invoice.amount_outstanding) + parseFloat($scope.Outstandings)).toFixed(2);
          })
        }
      }
      $scope.CalculateCredit();
    }

    $scope.selectPaymentType = function (data, index) {
      if (data == '') {
        $scope.Payment.payment_types_payments_attributes[index] = {
          amount: ''
        };
      }
      $scope.CalAmount();
    }
    //calculate credits

    $scope.CalculateCredit = function () {
      if ($rootScope.CreditAmount > 0) {
        $scope.TotalPayment = 0;
        $scope.Totalremaining = 0;
        $scope.CreditApplied = 0;
        $scope.TotalPayment = $rootScope.CreditAmount;
        if ($scope.ApplyInvoicesData) {
          var totalPaymentinvoice = parseFloat(angular.copy($scope.TotalPayment));
          $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
            invoice.credit_amount = 0;
            //$scope.unallocated = false;
            if (parseFloat($scope.PaymentApplied) < 0) {
              invoice.amount_remaining = invoice.amount_outstanding;
            }
            if (parseFloat(invoice.amount) <= parseFloat(invoice.amount_outstanding)) {
              invoice.amount_remaining = parseFloat(invoice.amount_outstanding)-parseFloat(invoice.amount);
            }
            if (totalPaymentinvoice > invoice.amount_remaining) {
              invoice.credit_amount = parseFloat(invoice.amount_remaining).toFixed(2);
              totalPaymentinvoice = parseFloat(totalPaymentinvoice - invoice.amount_remaining);
            } 
            else if (totalPaymentinvoice <= invoice.amount_remaining) {
              invoice.credit_amount = parseFloat(totalPaymentinvoice).toFixed(2);
              totalPaymentinvoice = 0;
            }
            invoice.amount_remaining = invoice.amount_remaining - invoice.credit_amount;
            $scope.Totalremaining = (parseFloat($scope.Totalremaining + invoice.amount_remaining)).toFixed(2);
            $scope.CreditApplied = (parseFloat(invoice.credit_amount + parseFloat($scope.CreditApplied))).toFixed(2);
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
    $scope.CalPayments = function (index) { 

      $scope.PaymentAmount = 0;
      $scope.PaymentApplied = 0;
      var invoice = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list[index];
      if (invoice.amount == '')
      {
        invoice.amount = 0;
      }
      invoice.amount_remaining = parseFloat(invoice.amount_outstanding - parseFloat(invoice.amount));
      $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
        $scope.PaymentApplied = (parseFloat(parseFloat(invoice.amount) + parseFloat($scope.PaymentApplied))).toFixed(2);
        if ($scope.PaymentApplied > $scope.AmountPaid) {
          $scope.unallocated = true;
          $scope.UnallocatedCredit = (parseFloat(parseFloat($scope.AmountPaid) - parseFloat($scope.PaymentApplied))).toFixed(2);
        } 
        else
        {
          $scope.unallocated = true;
          $scope.UnallocatedCredit = (parseFloat(parseFloat($scope.AmountPaid) - parseFloat($scope.PaymentApplied))).toFixed(2);
        }
      })
      if (invoice.amount_remaining < 0) {
        invoice.amount_remaining = 0;
      }
      $scope.CalculateCredit();
    }
    $scope.CalCredits = function (index) {
      $scope.CreditApplied = 0;
      $scope.Totalremaining = 0;
      var invoice = $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list[index];
      if (invoice.credit_amount == '' && invoice.credit_amount == 0)
      {
        invoice.credit_amount = 0;
      }
      invoice.amount_remaining = parseFloat(invoice.amount_outstanding - (parseFloat(invoice.credit_amount) + parseFloat(invoice.amount)));
      if (invoice.amount_remaining < 0) {
        invoice.amount_remaining = 0;
      }
      $scope.ApplyInvoicesData.rest_invoices.rest_invoices_list.forEach(function (invoice) {
        $scope.CreditApplied = parseFloat(parseFloat(invoice.credit_amount) + parseFloat($scope.CreditApplied));
        $scope.Totalremaining = (parseFloat(parseFloat($scope.Totalremaining) + parseFloat(invoice.amount_remaining))).toFixed(2);
      })
    }
    $scope.a = function () {
    }
    //Create Payment

    $scope.CreatePayment = function (Payment) {
        if (Payment.payment_date != null)
            Payment.payment_date = new Date(Payment.payment_date);
      var new_Date_month = Payment.payment_date.getMonth() + 1;
      var new_Date_day = Payment.payment_date.getDate();
      if (new_Date_month < 10)
        new_Date_month = '0' + new_Date_month;
      if (new_Date_day < 10)
        new_Date_day = '0' + new_Date_day;
      Payment.payment_date = Payment.payment_date.getFullYear() + '-' + new_Date_month + '-' + new_Date_day;
      $rootScope.cloading = true;
      $http.post('/payments/', {
        payment: Payment
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
        } 
        else {
          $rootScope.cloading = false;
          $scope.noData = false;
          $translate('toast.paymentAdded').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.cloading = false;
          $scope.Payment = {
            payment_types_payments_attributes: [
              {
                payment_type_id: '',
                amount: ''
              }
            ]
          };
          if ($stateParams.patient_id) {
            $state.go("patient-detail", {'patient_id':+ $stateParams.patient_id} , {reload: true});
            $rootScope.filterClientFiles($rootScope.ChkData);
            $rootScope.CountClientFile();
          }
          else if ($state.params.invoice_id != undefined && !$state.includes('appointment')) {
            $state.go('invoice.edit', {'invoice_id': $state.params.invoice_id}, { reload: true });
            // $rootScope.$parent.GetInvoice();
          }
          else if($stateParams.invoice_id && !$state.includes('appointment')){
            $state.go('invoice', {}, {reload: true});
            // $rootScope.$parent.GetInvoice();
          }
          else if($state.includes('appointment')){
            //$state.go("appointment");
            $rootScope.getEvents();
            $state.go('appointment.invoiceView', {
              'invoice_id': $state.params.invoice_id
            }, {reload: true}); 
          } 
          else {
            // $scope.$parent.PaymentListData();
            $state.go('payment', {}, {reload: true});
          }
          //$rootScope.GetInvoice();
        }
      });
    }
    $scope.goToInvoice = function(){
      $state.go('invoice', {}, {reload: true});
      // $rootScope.$parent.GetInvoice();
    }

  }
]);

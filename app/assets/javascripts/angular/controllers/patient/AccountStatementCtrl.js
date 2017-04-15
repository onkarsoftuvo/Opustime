app.controller('AccountStatementCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$translate',
  function ($rootScope, $scope, $state, $http, $translate) {
    $scope.patient_id = $state.params.patient_id;
    $scope.filterAttr = {};
    //get account statement
    $scope.getAccountStatement = function () {
      $rootScope.cloading = true;
      $scope.filterAttr = {}
      $http.post('/patients/' + $scope.patient_id + '/account_statement').success(function (results) {
        $rootScope.cloading = false;
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.accountstatement = results;
          $scope.calculate()
        }
      })
    }
    $scope.getAccountStatement()
    //apply filter on account statement
    $scope.applyFilter = function (data) {
      $rootScope.cloading = true;
      $http.post('/patients/' + $scope.patient_id + '/account_statement', data).success(function (results) {
        $rootScope.cloading = false;
        $scope.accountstatement = results;
        $scope.calculate();
      })
    }
    //email account statement to another email

    $scope.emailOther = function (data) {
      $rootScope.cloading = true;
      $http.get('/patients/' + $scope.patient_id + '/send_email?email_to=other').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      })
    }
    //email account statement to patient's email

    $scope.emailPatient = function (data) {
      $rootScope.cloading = true;
      $http.get('/patients/' + $scope.patient_id + '/send_email?email_to=patient').success(function (results) {
        $rootScope.cloading = false;
        $translate('toast.emailSentSuccess').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
      })
    }
    //calculation invoice and payment

    $scope.calculate = function () {
      $scope.total_invoice_tax = 0;
      $scope.total_invoice_amount = 0;
      $scope.total_payment_amount = 0;
      //invoice Calculation
      $scope.accountstatement.invoices.forEach(function (invoice) {
        $scope.total_invoice_amount = parseFloat(parseFloat($scope.total_invoice_amount) + parseFloat(invoice.invoice_amount)).toFixed(2);
        $scope.total_invoice_tax = parseFloat(parseFloat($scope.total_invoice_tax) + parseFloat(invoice.tax)).toFixed(2);
      });
      //payment Calculation
      $scope.accountstatement.payments.forEach(function (payment) {
        $scope.total_payment_amount = parseFloat(parseFloat($scope.total_payment_amount) + parseFloat(payment.total_paid)).toFixed(2);
      })
    }
    $scope.maxDate = new Date();
    $scope.open = function ($event) {
      $scope.opened = true;
    };
    $scope.open1 = function ($event) {
      $scope.opened1 = true;
    };
    $scope.thismonth = function () {
      var date = new Date();
      $scope.filterAttr.start_date = new Date(date.getFullYear(), date.getMonth(), 1);
      $scope.filterAttr.end_date = new Date(date.getFullYear(), date.getMonth() + 1, 0);
    }
    $scope.lastmonth = function () {
      var date = new Date();
      $scope.filterAttr.start_date = new Date(date.getFullYear(), date.getMonth() - 1, 1);
      $scope.filterAttr.end_date = new Date(date.getFullYear(), date.getMonth(), 0);
    }
    $scope.printAccountStatement = function () {
      var win = window.open('/patients/' + $scope.patient_id + '/account_statement/print.pdf', '_blank');
      win.focus();
    }
  }
]);


app.controller('integrationCtrl', [
  '$scope',
  '$http',
  '$rootScope',
  '$uibModal',
  '$translate',
  '$state',
  function ($scope, $http, $rootScope, $uibModal, $translate, $state) {
    $scope.APIvalid = false;
    $scope.apiNotValid = false;
    $scope.integration = {};
    $scope.quickElements = {};
    $scope.mailchip = true;
    $scope.xero = false;
    $scope.xero = false;
    $scope.QuickBook = false;
    $scope.facebookBooking = false;
    $scope.xeroNotConect = true;
    $scope.quickBookNotConect = true;
    $scope.xeroConect = false;
    $scope.quickBookConnect = false;
    
    $scope.xeroElements = {};
    //default values for xero listing
    $scope.xeroElements.choose_sales = 'choose_sales';
    $scope.xeroElements.choose_account = 'choose_account';
    $scope.xeroElements.choose_tax = 'choose_tax';
   
    //integration tabbing
    $scope.openMailchip = function(){
    	$scope.mailchip = true;
    	$scope.xero = false;
      $scope.QuickBook = false;
    };
    $scope.openXero = function(){
    	$scope.mailchip = false;
    	$scope.xero = true;
      $scope.QuickBook = false;
    };
    $scope.openQuickBook = function(){
    	$scope.mailchip = false;
    	$scope.xero = false;
      $scope.QuickBook = true;
    };

    /*get xero listing data*/
    /*function getXeroData() {
      $rootScope.cloading = true;
      $http.get('settings/xero_sessions/connect_info').success(function (results) {
        $rootScope.cloading = false;
        $scope.xeroData = results;
        if (results.is_connected == true) {
          if(results.selected_account_invoice_item !=null){
            $scope.xeroElements.choose_sales = results.selected_account_invoice_item;
          }
          else{
            $scope.xeroElements.choose_sales = 'choose_sales';
          }
          if(results.selected_account_payment !=null){
            $scope.xeroElements.choose_account = results.selected_account_payment;
          }
          else{
            $scope.xeroElements.choose_account = 'choose_account';
          }
          if(results.seleced_account_tax_rate !=null){
            $scope.xeroElements.choose_tax = results.seleced_account_tax_rate;
          }
          else{
            //$scope.xeroElements.choose_tax = 'choose_tax';
            $scope.xeroElements.choose_tax = results.account_tax_rates_list[0].item_code;
          }
          if(results.is_connected){
            $scope.xeroNotConect = false;
            $scope.xeroConect = true;
          }
          else{
            $scope.xeroNotConect = true;
            $scope.xeroConect = false;
          }
        }
      });
    };*/

    

    /*get oauth token and hit to get listing data*/  
    /*function oauth_token(){
      var oauthData = location.hash;
      var splitOauth = oauthData.split('?');
      if(splitOauth.length != 0){
        for(i = 0; i < splitOauth.length; i++){
          if (splitOauth[i].indexOf("oauth_token") >= 0){
            $http.get('/xero/complete?' + splitOauth[i]).success(function (results) {
              $rootScope.cloading = false;
              $scope.xeroData = results;
              $scope.xeroElements.choose_tax = results.account_tax_rates_list[0].item_code;
              if(results.is_connected){
                $scope.xeroNotConect = false;
                $scope.xeroConect = true;
              }
              else{
                $scope.xeroNotConect = true;
                $scope.xeroConect = false;
              }
            });
          }
        }
      }
    };*/

    /*if(localStorage.getItem('xeroActive') == 'true'){
      $scope.mailchip = false;
      $scope.xero = true;
      $scope.facebookBooking = false;
      oauth_token();
      localStorage.setItem('xeroActive', false);
    }
    else{
      getXeroData();
    }*/

    /*get oauth token and hit to get listing data*/  
    /*function oauth_token_Quickbook(){
      var oauthToken = location.hash;
      var splitQuickOauth = oauthToken.split('?');
      console.log(splitQuickOauth);
      if(splitQuickOauth.length != 0){
        for(i = 0; i < splitQuickOauth.length; i++){
          if (splitQuickOauth[i].indexOf("oauth_token") >= 0){
            $http.get('/xero/complete?' + splitQuickOauth[i]).success(function (results) {
            });
          }
        }
      }
    };*/
      $scope.quickElements = {};

    /*get QuickbookData listing data*/
    function getQuickbookData() {
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/status?comp_id=' + $rootScope.User_id).success(function (results) {
        $rootScope.cloading = false;
        $scope.quickBookData = results;

        if (results.is_connected) {
          results.data[0].Expense[0].Name = results.data[0].Expense[0].Name + " (Default)";
          results.data[1].Income[0].Name = results.data[1].Income[0].Name + " (Default)";
          if (results.data[2].Tax.length) {
            results.data[2].Tax[0].name = results.data[2].Tax[0].name + " (Default)";
          }
          
          /*results.data[2].Tax.forEach(function(taxData){
            taxData.id = ''+taxData.id;
          })*/
          $scope.quickBookData = results;
          $scope.quickBookConnect = true;
          $scope.quickBookNotConect = false;

          if(results.data[0].selected_id == null || results.data[0].selected_id == ""){
            $scope.quickElements.expense = results.data[0].Expense[0].Id;
          }
          else{
            $scope.quickElements.expense = results.data[0].selected_id;
          }

          if(results.data[1].selected_id == null || results.data[1].selected_id == ""){
            $scope.quickElements.income = results.data[1].Income[0].Id;
          }
          else{
            $scope.quickElements.income = results.data[1].selected_id;
          }

          if(results.data[2].selected_id == null || results.data[2].selected_id == "" && results.data[2].Tax.length >= 1){
            $scope.quickElements.tax = results.data[2].Tax[0].Id;
          }
          else{
            $scope.quickElements.tax = results.data[2].selected_id;
          }
        }
        else{
          $scope.quickBookConnect = false;
          $scope.quickBookNotConect = true; 
        }
      });
    };

    if(localStorage.getItem('QuickbookActive') == 'true'){
      $scope.mailchip = false;
      $scope.xero = false;
      $scope.QuickBook = true;
      getQuickbookData();
      localStorage.setItem('QuickbookActive', false);
    }
    else{
      getQuickbookData();
    }
    //save quickbook data

    $scope.saveQuickBook = function(data){
      console.log(data);
      $rootScope.cloading = true;
      var quickData = {};
      quickData.expense_account_ref = data.expense;
      quickData.income_account_ref = data.income;
      quickData.company_id = $rootScope.User_id;
      quickData.tax_code_ref = data.tax;
      $http.post('/settings/quickbook/save_account_setting', quickData).success(function(result){
        $rootScope.cloading = false;
        if (result.flag) {
          //getQuickbookData();
          $rootScope.showSimpleToast('QuickBook Data updated successfull');
        }
        else{
          $rootScope.errors = result.error;
          $rootScope.showMultyErrorToast();
        }
      });
    }
    //save integration mailchip key
    $scope.saveIntegration = function (data) {
      $rootScope.cloading = true;
      $http.post('settings/integrations/mail_chimp?mailchimp_key=' + data.key + '&list_name=' + data.list).success(function (results) {
        $rootScope.cloading = false;
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          if (results.flag == false) {
            $scope.APIvalid = false;
            $scope.apiNotValid = true;
          } 
          else {
            $scope.APIvalid = true;
            $scope.apiNotValid = false;
          }
        }
        
      });
    };

    //get integration mailchip data
    function getMailchipData(){
    	$rootScope.cloading = true;
    	$http.get('/settings/integrations/mail_chimp/info').success(function (data) {
        if (!data.code) {
          $scope.integration.key = data.mail_chimp_info.key;
          $scope.integration.list = data.mail_chimp_info.list_name;
          if(data.mail_chimp_info.flag){
            $scope.APIvalid = true;
                $scope.apiNotValid = false;
          }
          else{
            $scope.APIvalid = false;
                $scope.apiNotValid = true;
          }
        }
    		$rootScope.cloading = false;
    	});
    };
    getMailchipData();

    //to connect to xero
    $scope.connectToXero = function(){
      localStorage.setItem('xeroActive', true);
      location.href = '/settings/xero_sessions/new'
    };

    $scope.connectToQuick = function(){
      localStorage.setItem('QuickbookActive', true);
      location.href = '/settings/quickbook/authenticate'
    }

    //to disconnect Xero popup
    $scope.disconnectXero = function () {
      $rootScope.modalInstance = $uibModal.open({
        templateUrl: 'DisconnectXero.html',
        controller: 'DisconnectXeroCtrl',
        size: 'sm'
      });
    };

    //to disconnect QuickBook popup
    $scope.disconnectQuickBook = function () {
      $rootScope.modalInstance = $uibModal.open({
        templateUrl: 'DisconnectQuickbook.html',
        controller: 'DisconnectQuickbookCtrl',
        size: 'sm'
      });
    };

    

    //to disconnect from xero
    $scope.disconnectIt = function(){
      $rootScope.cloading = true;
      $http.get('settings/xero_sessions/disconnect').success(function (data) {
        $scope.xeroData = data;
        $translate('toast.xeroDisConnect').then(function (msg) {
          $rootScope.showSimpleToast(msg);
        });
        if(!data.is_connected){
          $scope.xeroNotConect = true;
          $scope.xeroConect = false;
        }
        else{
          $scope.xeroNotConect = false;
          $scope.xeroConect = true;
        }
        $rootScope.cloading = false;
      });
    };
    //to disconnect from xero
    $scope.disconnectQuick = function(){
      $rootScope.cloading = true;
      $http.get('/settings/quickbook/disconnect?id=' + $scope.quickBookData.id).success(function (data) {
        $rootScope.cloading = false;
        if (data.is_connected) {
          $scope.quickBookConnect = true;
          $scope.quickBookNotConect = false;
        }
        else{
          $scope.quickBookConnect = false;
          $scope.quickBookNotConect = true;
        }
      });
    };

    //confirm xero delete
    $rootScope.disconnectFromXero = function(){
      $rootScope.modalInstance.close($scope.disconnectIt());
    }



    $rootScope.disconnectFromQuickBook = function(){
      $rootScope.modalInstance.close($scope.disconnectQuick());
    }

    //save xero settings
    $scope.saveXero = function(data){
  	  $scope.xeroRecord = {};
  	  $scope.xeroRecord.inv_item_code = data.choose_sales;
  	  $scope.xeroRecord.payment_code = data.choose_account;
  	  $scope.xeroRecord.tax_rate_code = data.choose_tax;
  	  $http.put('/settings/xero_sessions/save_info' , $scope.xeroRecord).success(function (data) {
        if(data.flag){
          $translate('toast.xeroConnect').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
  	  });
    };

    //synchronised invoices popup
    $scope.synchronised_invoices_Modal = function () {
      var modalInstance = $uibModal.open({
        templateUrl: 'synchronised_invoices.html',
        controller: 'synchronised_invoicesCtrl',
        size: 'md'
      });
    };
  }
]);

//Synchronised invoices popup controller
app.controller('synchronised_invoicesCtrl', [
  '$scope',
  '$http',
  '$modalInstance',
  function ($scope, $http, $modalInstance) {
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    }
  }
]);

/*Confirmation Modal controler*/
app.controller('DisconnectXeroCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, event, $translate) {
    /*close modal*/
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
  }
]);

/*Confirmation Modal controler*/
app.controller('DisconnectQuickbookCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  '$translate',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, event, $translate) {
    /*close modal*/
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
  }
]);
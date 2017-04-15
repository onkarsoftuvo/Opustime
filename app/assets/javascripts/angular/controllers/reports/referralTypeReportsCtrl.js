app.controller('referralTypeReportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$http',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $http, $state) {
    $scope.pieChart = {};
    $scope.pieChart.labels = [];
    $scope.pieChart.data = [];

    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.graphFromDate = {opened: false};
    $scope.graphToDate = {opened: false};

    var date = new Date();
    $scope.graphfilter = {};
    $scope.graphfilter.from = new Date(date.getFullYear(), date.getMonth(), 1);;
    $scope.graphfilter.to = date;

    $scope.chartFilter = '0';
    $scope.st_hr = 12;
    $scope.st_min = 0;
    $scope.st_time = 'AM';
    $scope.end_hr = 11;
    $scope.end_min = 59;
    $scope.end_time = 'PM';

    $scope.noData = false;
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };

    $scope.openFromDate = function ($event) {
      $scope.graphFromDate.open = true;
    };
    $scope.openToDate = function ($event) {
      $scope.graphToDate.open = true;
    };
    $scope.stopEvent = function (events) {
      events.stopPropagation();
    }
    $scope.chart_options = {
      segmentShowStroke : false,
      animationEasing : "linear"
    }  

    //to Show Side Date picker
    $scope.showDatePicker = false;
    var pickerStatus = 0;
    $scope.showPicker = function () {
      if (pickerStatus == 0) {
        $scope.showDatePicker = true;
        pickerStatus = 1;
      } 
      else {
        $scope.showDatePicker = false;
        pickerStatus = 0;
      }
    }
    $scope.dontShow = false;
    $scope.todayDate = new Date();
    $scope.chartDate = new Date();

    //get all business list
    /*function getAllBus(){
      Data.get('/daily_reports/locations').then(function(data){
        $scope.allLoc = data.locations;
        $scope.business = $scope.allLoc[0].id;
        $scope.getChartData();
      });
    };
    getAllBus(); */

    $scope.filterGraph = function () {
      var barData = [];
      var labels = []
      $rootScope.cloading = true;
      var startDate = $scope.graphfilter.from.getFullYear() +'-'+ ($scope.graphfilter.from.getMonth()+1) +'-'+ $scope.graphfilter.from.getDate();
      var endDate = $scope.graphfilter.to.getFullYear() +'-'+ ($scope.graphfilter.to.getMonth()+1) +'-'+ $scope.graphfilter.to.getDate();
      Data.get("/referral_type_patients/chart_data?start_date=" + startDate + "&end_date=" + endDate).then(function (data) {
        if (!data.code) {
          data.series.forEach(function(series){
            labels.push(series.name);
            barData.push(series.data);
          });
          $scope.pieChart.data = barData;
          $scope.totalCount = 0;
          for(i=0; i<$scope.pieChart.data.length; i++){
            $scope.totalCount = $scope.totalCount+$scope.pieChart.data[i];
          }
          $scope.pieChart.labels = labels;
        }
        
        $rootScope.cloading = false;
      });
    };
    $scope.filterGraph();

    

    $scope.updateChart = function(date){
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.chartDate = new Date(date.setDate(date.getDate()));

      pickerStatus = 0;
      if($scope.chartDate.getDate() == $scope.todayDate.getDate() && $scope.chartDate.getMonth() == $scope.todayDate.getMonth() && $scope.chartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.showDatePicker = false;
      $scope.getChartData();
    };

    //get month name from month number
    $scope.getMonthName = function (date) {
      return monthNameServiceSmall.month(date.getMonth());
    }; 
    //Previous Date
    $scope.preDate = function (date) {
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.chartDate = new Date(date.setDate(date.getDate() - 1));
      if($scope.chartDate.getDate() == $scope.todayDate.getDate() && $scope.chartDate.getMonth() == $scope.todayDate.getMonth() && $scope.chartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.getChartData();
    }; 

    //Next Date
    $scope.nextDate = function (date) {
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.chartDate = new Date(date.setDate(date.getDate() + 1));
      if($scope.chartDate.getDate() == $scope.todayDate.getDate() && $scope.chartDate.getMonth() == $scope.todayDate.getMonth() && $scope.chartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.getChartData();
    };   

    
       

    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.alldoc = '';
      $scope.allref = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/referral_type_patients/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/referral_type_patients/generate_pdf.pdf?'
          $scope.printIndication = false;
        }
        else{
          var baseurl = '/referral_type_patients?'
        }
        var filter = $scope.filter;
        var i = 0;
        $scope.allFilters.doctor.forEach(function (doc) {
          if (doc.ischecked) {
            if (i > 0) {
              $scope.alldoc += ',' + doc.id;
            } 
            else if (i == 0) {
              $scope.alldoc += doc.id;
            }
            i++;
          }
        });
        var k = 0;
        $scope.allFilters.referral.forEach(function (reff) {
          if (reff.ischecked) {
            if (k > 0) {
              $scope.allref += ',' + reff.id;
            } 
            else if (k == 0) {
              $scope.allref += reff.id;
            }
            k++;
          }
        });
        if (filter.from) {
          baseurl += 'st_date=' + (filter.from.getDate() + '/' + (parseInt(filter.from.getMonth()) + 1) + '/' + filter.from.getFullYear());
        }
        if (filter.to) {
          baseurl += '&end_date=' + (filter.to.getDate() + '/' + (parseInt(filter.to.getMonth()) + 1) + '/' + filter.to.getFullYear());
        }
        if ($scope.allref != '') {
          baseurl += '&referral_id=' + $scope.allref;
        }
        if ($scope.alldoc != '') {
          baseurl += '&doc_id=' + $scope.alldoc;
        }
        return resolve(baseurl)
      });
    }
    $scope.getReferralReports = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allReportsList = data.list;
          if ($scope.allReportsList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          //default check checkboxes
          var docs = $scope.alldoc.split(',');
          for (j = 0; j < docs.length; j++) {
            $scope.allFilters.doctor.forEach(function (docters) {
              if (docters.id == parseInt(docs[j])) {
                docters.ischecked = true;
              }
            });
          }
          var reffs = $scope.allref.split(',');
          for (k = 0; k < reffs.length; k++) {
            $scope.allFilters.referral.forEach(function (referrals) {
              if (referrals.id == parseInt(reffs[k])) {
                referrals.ischecked = true;
              }
            });
          }
          $rootScope.cloading = false;
        });
      });
    };

    //onload table content data
    $scope.allReferralReportData = function () {
      $rootScope.cloading = true;
      Data.get('/referral_type_patients').then(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.allFilters = data;
          $scope.allReportsList = data.list;
          if ($scope.allReportsList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          $scope.filter.from = '';
          $scope.filter.to = '';
        }
        
        $rootScope.cloading = false;
      });
    }
    $scope.allReferralReportData();

    //export data
    $scope.export = function(){
      $scope.exportIndication = true;
      var promise = buildFilters();
      promise.then(function (results) {
        var win = window.open(results, '_blank');
      });
    }
    //print data
    $scope.print = function(){
      $scope.printIndication = true;
      var promise = buildFilters();
      promise.then(function (results) {
        var win = window.open(results, '_blank');
      });
    }

    //add to dashboard button
    $scope.addDash = {};
    function getAddDash(){
      $http.get('/dashboard/get_report_options').success(function(data){
        $scope.addDash.refer_type = data.refer_type;
      });
    };
    getAddDash();

    $scope.addToDashboard = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = 'refer_type';
      $scope.report_options.val = data;
      $scope.report_options = {'report_options' : $scope.report_options};
      $http.post('/dashboard/report_options', $scope.report_options).success(function(result){
        if (result.flag) {
          //$rootScope.showSimpleToast('chart added to dashborad');
        }
        else{
          $rootScope.errors = data.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
        }
      });
    };
  }
]);

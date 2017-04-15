app.controller('dailyReportsCtrl', [
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
    function getAllBus(){
      Data.get('/daily_reports/locations').then(function(data){
        if (data.locations) {
          $scope.allLocations = data.locations;
          $scope.business = $scope.allLocations[0].id;
          $scope.getChartData();
        }
      });
    };
    getAllBus();

    $scope.getChartData = function () {
      var barData = [];
      var labels = []
      $rootScope.cloading = true;
      var calDate = $scope.chartDate.getFullYear() +'-'+ ($scope.chartDate.getMonth()+1) +'-'+ $scope.chartDate.getDate()
      Data.get("/daily_reports/chart_data?bus_id=" + $scope.business + "&dt=" + calDate).then(function (data) {
        console.log(data);
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
        $rootScope.cloading = false;
      });
    };



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
      $scope.allLoc = '';
      $scope.allpaymentType = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/daily_reports/list/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/daily_reports/list/pdf.pdf?'
          $scope.printIndication = false;
        }
        else{
          var baseurl = '/daily_reports?'
        }
        var filter = $scope.filter;
        var i = 0;
        $scope.allFilters.locations.forEach(function (loc) {
          if (loc.ischecked) {
            if (i > 0) {
              $scope.allLoc += ',' + loc.id;
            }
            else if (i == 0) {
              $scope.allLoc += loc.id;
            }
            i++;
          }
        });
        var k = 0;
        $scope.allFilters.payment_types.forEach(function (pay) {
          if (pay.ischecked) {
            if (k > 0) {
              $scope.allpaymentType += ',' + pay.id;
            }
            else if (k == 0) {
              $scope.allpaymentType += pay.id;
            }
            k++;
          }
        });
        if (filter.from) {
          baseurl += 'st_date=' + (filter.from.getDate() + '/' + (parseInt(filter.from.getMonth()) + 1) + '/' + filter.from.getFullYear());
        }
        if ($scope.allpaymentType != '') {
          baseurl += '&p_type_id=' + $scope.allpaymentType;
        }
        if ($scope.allLoc != '') {
          baseurl += '&bs_id=' + $scope.allLoc;
        }
        return resolve(baseurl)
      });
    }
    $scope.getdailyReports = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allReportsList = data.revenues;
          if ($scope.allReportsList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          //default check checkboxes
          var locs = $scope.allLoc.split(',');
          for (j = 0; j < locs.length; j++) {
            $scope.allFilters.locations.forEach(function (locations) {
              if (locations.id == parseInt(locs[j])) {
                locations.ischecked = true;
              }
            });
          }
          var pays = $scope.allpaymentType.split(',');
          for (k = 0; k < pays.length; k++) {
            $scope.allFilters.payment_types.forEach(function (payments) {
              if (payments.id == parseInt(pays[k])) {
                payments.ischecked = true;
              }
            });
          }
          $rootScope.cloading = false;
          getAllBus()
        });
      });
    };

    //onload table content data
    $scope.allDailyReportData = function () {
      $rootScope.cloading = true;
      Data.get('/daily_reports').then(function (data) {
        console.log(data);
        if (data.revenues) {
          $scope.allFilters = data;
          $scope.allReportsList = data.revenues;
          if ($scope.allReportsList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          $scope.filter.from = '';
        }
        else{
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }

        $rootScope.cloading = false;
      });
    }
    $scope.allDailyReportData();

    //export data
    $scope.export = function(){
      $scope.exportIndication = true;
      var promise = buildFilters();
      promise.then(function (results) {
        console.log(results);
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
        $scope.addDash.daily_report = data.daily_report;
      });
    };
    getAddDash();

    $scope.addToDashboard = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = 'daily_report';
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

angular.module('Zuluapp').controller('dashboardCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$timeout',
  '$http',
  'weekServiceSmall',
  'monthNameServiceSmall',
  'Data',
  'dayService',
  '$uibModal',
  '$state',
  function ($scope, $location, $rootScope, $timeout, $http, weekServiceSmall, monthNameServiceSmall, Data, dayService, $uibModal, $state) {
    $scope.$broadcast('rebuild:me');
    $rootScope.cloading = true;

    $scope.getPermission = function(){
      $http.get('/dashboard/admin_permission').success(function(result){
      $scope.permissions = result.ds_permission;
      });
    }
    $scope.getPermission();
    //get dashboard authorization
    $rootScope.getAtendee();
    $scope.AutherizeDashboard = function () {
      $http.get('/dashboard/modules').success(function (response) {
        $rootScope.DashboardLinks = response;
      });
    }
    $scope.AutherizeDashboard();
    //get current loged in user role
    $scope.userRole = function () {
      $http.get('/patients/get/authority').success(function (data) {
        $rootScope.roleData = data;
      });
    }
    $scope.userRole();

    /*------------dashboard content start here------------*/

    $scope.currentDate = new Date();
    $scope.dashDate = {
      opened: false
    };
    $scope.openDashDate = function ($event) {
      $scope.dashDate.opened = true;
    };
    function dashboardContent(date) {
      var stDate = date.getFullYear() + '-' + (date.getMonth()+1) + '-' + date.getDate();
      $http.get('/dashboard?dt=' + stDate + '&bs_id=' + $scope.dashboardBusiness).success(function(data){
        $scope.dashboardCon = data;
      });
    };
    $scope.updateDashDate = function(date){
      $scope.currentDate = date;
      dashboardContent($scope.currentDate);
      overallSalesChart();
      serviceSalesChart();
      appointmentChart(0);
      salesChart(0);
      appointmentData();
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = true;
      $scope.payment_activity = false;
      appActivity('5');

      /*if ($scope.app_activity) {
        appActivity('1');
      }
      else if($scope.invoice_activity){
        appActivity('2');
      }
      else if($scope.payment_activity){
        appActivity('3');
      }
      else if($scope.expense_activity){
        appActivity('4');
      }
      else if($scope.sms_activity){
        appActivity('5');
      }*/
    }

    $scope.updateBusiness = function(id){
      $scope.allLocations.forEach(function(data){
        if (data.id == id) {
          $scope.country = data.country;
          $scope.city = data.city;
        }
      });
      dashboardContent($scope.currentDate);
      overallSalesChart();
      serviceSalesChart();
      appointmentChart(0);
      salesChart(0);
      appointmentData();
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = true;
      $scope.payment_activity = false;
      appActivity('5');

      /*if ($scope.app_activity) {
        appActivity('1');
      }
      else if($scope.invoice_activity){
        appActivity('2');
      }
      else if($scope.payment_activity){
        appActivity('3');
      }
      else if($scope.expense_activity){
        appActivity('4');
      }
      else if($scope.sms_activity){
        appActivity('5');
      }*/
    }

    /*decrease dashboard date*/
    $scope.preDateDash = function(){
      $scope.currentDate = new Date($scope.currentDate.setDate($scope.currentDate.getDate() - 1));
      dashboardContent($scope.currentDate);
      overallSalesChart();
      serviceSalesChart();
      appointmentChart(0);
      salesChart(0);
      appointmentData();
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = true;
      $scope.payment_activity = false;
      appActivity('5');

      /*if ($scope.app_activity) {
        appActivity('1');
      }
      else if($scope.invoice_activity){
        appActivity('2');
      }
      else if($scope.payment_activity){
        appActivity('3');
      }
      else if($scope.expense_activity){
        appActivity('4');
      }
      else if($scope.sms_activity){
        appActivity('5');
      }*/
    }
    /*increase dashboard date*/
    $scope.nextDateDash = function(){
      $scope.currentDate = new Date($scope.currentDate.setDate($scope.currentDate.getDate() + 1));
      dashboardContent($scope.currentDate);
      overallSalesChart();
      serviceSalesChart();
      appointmentChart(0);
      salesChart(0);
      appointmentData();
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = true;
      $scope.payment_activity = false;
      appActivity('5');

      /*if ($scope.app_activity) {
        appActivity('1');
      }
      else if($scope.invoice_activity){
        appActivity('2');
      }
      else if($scope.payment_activity){
        appActivity('3');
      }
      else if($scope.expense_activity){
        appActivity('4');
      }
      else if($scope.sms_activity){
        appActivity('5');
      }*/

    }


    /*get month name from month number*/
    $scope.getDay = function (date) {
      return dayService.day(date.getDate()-1);
    }

    /*------------dashboard content ends here------------*/

    /*-----------------Activity tabs starts------------------*/
    $scope.app_activity = false;
    $scope.invoice_activity = false;
    $scope.expense_activity = false;
    $scope.sms_activity = true;
    $scope.payment_activity = false;

    $scope.openApp = function () {
      $scope.app_activity = true;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = false;
      $scope.payment_activity = false;
      appActivity('1');
    }
    $scope.openInc = function () {
      $scope.app_activity = false;
      $scope.invoice_activity = true;
      $scope.expense_activity = false;
      $scope.sms_activity = false;
      $scope.payment_activity = false;
      appActivity('2');
    }
    $scope.openExpense = function () {
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = true;
      $scope.sms_activity = false;
      $scope.payment_activity = false;
      appActivity('4');
    }
    $scope.openSms = function () {
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = true;
      $scope.payment_activity = false;
      appActivity('5');
    }
    $scope.openPayment = function () {
      $scope.app_activity = false;
      $scope.invoice_activity = false;
      $scope.expense_activity = false;
      $scope.sms_activity = false;
      $scope.payment_activity = true;
      appActivity('3');
    }

    //get appointment activity logs
    function appActivity(obj_tab){
      var stDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/activity_logs?dt=' + stDate + '&tb=' + obj_tab + '&bs_id=' + $scope.dashboardBusiness).success(function(data){
        $scope.activityLogs = data;
          //console.log(data);
      });
    }


    /*-----------------Activity tabs ends------------------*/


    /*-----------------Sales chart starts------------------*/

    $scope.salesOverallChart = {};

    function overallSalesChart(){
      var overallData = [];
      var overallLabels = []
      var chartDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/item_sales_chart?chart_type=overall&bs_id=' + $scope.dashboardBusiness + '&dt=' + chartDate).success(function(data){
        data.forEach(function(series){
          overallLabels.push(series.name);
          overallData.push(series.amount);
        });
        $scope.salesOverallChart.data = overallData;
        $scope.totalSales = 0;
        $scope.salesOverallChart.data.forEach(function(total){
          $scope.totalSales+= total;
        })
        $scope.salesOverallChart.labels = overallLabels;
      });
    };
    overallSalesChart();

    $scope.salesServiceChart = {};

    function serviceSalesChart(){
      var serviceData = [];
      var serviceLabels = []
      var serviceDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/item_sales_chart?bs_id=' + $scope.dashboardBusiness + '&dt=' + serviceDate).success(function(data){
        data.forEach(function(series){
          serviceLabels.push(series.name);
          serviceData.push(series.amount);
        });
        $scope.salesServiceChart.data = serviceData;
        $scope.totalService = 0;
        $scope.salesServiceChart.data.forEach(function(total){
          $scope.totalService+= total;
        })
        $scope.salesServiceChart.labels = serviceLabels;
      });
    };
    serviceSalesChart();
    /*-----------------Sales chart ends------------------*/

    /*----------------appointment Chart code start--------------*/
    var chart = nv.models.multiBarChart();
    $scope.disableMin = true;
    chart.multibar.stacked(true); // default to stacked
    //chart.showControls(false); // don't show controls

    //chart.legend.margin({top: 10, right:0, left:0, bottom: 0});
    var appOffset = 0;
    var appArray = [];
    function appointmentChart(currentOffset){
      var stDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/appnts_reports?off_set=' + currentOffset + '&bs_id=' + $scope.dashboardBusiness + '&dt=' + stDate).success(function(data){
        $scope.isNext = data.next;
        data.result[0].color = '#51A351';
        data.result[1].color = '#d3314e';
        data.result[2].color = '#343f6a';
        d3.select('#chart svg').datum(data.result).transition().duration(500).call(chart);
      });
    };

    //next offset
    $scope.nextOffset = function(){
      appOffset+=1;
      $scope.isNext = false;
      appointmentChart(appOffset);
      if (appOffset == 0) {
        $scope.disableMin = true;
      }
      else{
        $scope.disableMin = false;
      }
    }
    //previous offset
    $scope.preOffset = function(){
      if (appOffset != 0) {
        appOffset-=1;
      }
      appointmentChart(appOffset);
      if (appOffset == 0) {
        $scope.disableMin = true;
      }
      else{
        $scope.disableMin = false;
      }
    }
    /*----------------appointment Chart code ends--------------*/

    /*----------------Sales Chart code start--------------*/
    var chartSale = nv.models.multiBarChart();
    chartSale.multibar.stacked(true); // default to stacked
    //chartSale.showControls(false); // don't show controls
    //chartSale.legend.margin({top: 10, right:0, left:0, bottom: 0});
    var salesOffset = 0;
    var salesArray = [];
    $scope.disableSaleMin = true;
    function salesChart(currentSaleOffset){
      var stDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/sales_chart?off_set=' + currentSaleOffset + '&bs_id=' + $scope.dashboardBusiness + '&dt=' + stDate).success(function(data){
        $scope.isNextSale = data.next;
        data.result[0].color = '#51A351';
        data.result[1].color = '#d3314e';
        d3.select('#saleChart svg').datum(data.result).transition().duration(500).call(chartSale);
      });
    };

    //next offset
    $scope.nextSaleOffset = function(){
      salesOffset+=1;
      salesChart(salesOffset);
      if (salesOffset == 0) {
        $scope.disableSaleMin = true;
      }
      else{
        $scope.disableSaleMin = false;
      }
    }
    //previous offset
    $scope.preSaleOffset = function(){
      if (salesOffset != 0) {
        salesOffset-=1;
      }
      salesChart(salesOffset);
      if (salesOffset == 0) {
        $scope.disableSaleMin = true;
      }
      else{
        $scope.disableSaleMin = false;
      }
    }
    /*----------------Sales Chart code ends--------------*/

    /*----------------Appointments code ends--------------*/
    function appointmentData(){
      var startDate = $scope.currentDate.getFullYear() + '-' + ($scope.currentDate.getMonth()+1) + '-' + $scope.currentDate.getDate();
      $http.get('/dashboard/coming_appnt?bs_id=' + $scope.dashboardBusiness + '&dt=' + startDate).success(function(data){
        $scope.appointmentRecord = data;
        $scope.totalApps = 0;
        data.forEach(function(apps){
          $scope.totalApps += apps.appnts.length;
        });
      });
    }
    /*----------------Appointments code ends--------------*/

    /*------------------appointment chart start------------------------*/
    $scope.activeBtn = 0;
    $scope.type = 'summary';

    $scope.chart_options = {
      datasetFill: false,
      scaleShowHorizontalLines: true,
      scaleShowVerticalLines: true,
      legendTemplate: '<ul class="tc-chart-js-legend line-legend"><% for (var i=0; i<datasets.length; i++){%><li><span class="line-legend-icon" style="background-color:<%=datasets[i].strokeColor%>;"></span><span class="line-legend-text" style="color:<%=datasets[i].strokeColor%>"><%if(datasets[i].label){%><%=datasets[i].label%><%}%></span></li><%}%></ul>'
    }
    //to Show Side Date picker
    $scope.showAppDatePicker = true;
    var pickerStatus = 0;
    $scope.showAppPicker = function () {
      if (pickerStatus == 0) {
        $scope.showAppDatePicker = true;
        pickerStatus = 1;
      }
      else {
        $scope.showAppDatePicker = false;
        pickerStatus = 0;
      }
    }
    $scope.getChartData = function (appType) {
      var barData = [];
      var Series = [];
      $rootScope.cloading = true;
      var period;
      if ($scope.activeBtn == 0) {
        period = 'week';
      }
      else if($scope.activeBtn == 1){
        period = 'month';
      }
      else{
        period = 'year';
      }
      var start_date = $scope.firstday.getDate() + '/' + (parseInt($scope.firstday.getMonth()) + 1) + '/' + $scope.firstday.getFullYear();
      var end_date = $scope.lastday.getDate() + '/' + (parseInt($scope.lastday.getMonth()) + 1) + '/' + $scope.lastday.getFullYear();
      Data.get('/reports?period=' + period + '&start_date=' + start_date + '&end_date=' + end_date + '&type=' + $scope.type).then(function (data) {
        if (!data.code) {
          data.series.forEach(function (series) {
            Series.push(series.name);
            barData.push(series.data);
          });
          $scope.barChart.data = barData;
          var labels_ele = [];
          if($scope.activeBtn == 1){
            for(i=1; i<=$scope.barChart.data[0].length; i++){
              labels_ele.push([i])
            }
            $scope.barChart.labels = labels_ele;
          }
          $scope.barChart.series = Series;
          $scope.weekCount = data.weekly_appointments;
          $scope.monthCount = data.monthly_appointments;
          $scope.yearCount = data.yearly_appointments;
        }
        $rootScope.cloading = false;
      });
    };

    $scope.chartDate = new Date();
    /*update chart dates*/
    $scope.updateChart = function (date) {
      $scope.chartDate = date;
      if ($scope.activeBtn == 0) {
        $scope.firstday = new Date(date.setDate(date.getDate() - date.getDay()));
        $scope.lastday = new Date(date.setDate(date.getDate() - date.getDay() + 6));
      }
      else if ($scope.activeBtn == 1) {
        $scope.firstday = new Date(date.getFullYear(), date.getMonth(), 1);
        $scope.lastday = new Date(date.getFullYear(), date.getMonth()+1, 0);
      }
      else if ($scope.activeBtn == 2) {
        $scope.firstday = new Date(date.getFullYear(), 0, 1);
        $scope.lastday = new Date(date.getFullYear(), 12, 0);
      }
      $scope.showAppDatePicker = false;
      pickerStatus = 0;
      $scope.getChartData();
    }


    /*get month name from month number*/
    $scope.getMonthName = function (date) {
      return monthNameServiceSmall.month(date.getMonth());
    }

    /*next Date*/
    $scope.nextDate = function (date) {
      if ($scope.activeBtn == 0) {
        $scope.nextday = new Date(date.setDate(date.getDate() + 7));
        /*$scope.chartDate = $scope.nextday;
        $scope.showWeek();*/
      }
      else if($scope.activeBtn == 1){
        $scope.nextday = new Date(date.setMonth(date.getMonth() + 1));
      }
      else{
        $scope.nextday = new Date(date.setFullYear(date.getFullYear() + 1));
      }
      $scope.updateChart($scope.nextday);
    }

    /*Previous Date*/
    $scope.preDate = function (date) {
      if ($scope.activeBtn == 0) {
        $scope.nextday = new Date(date.setDate(date.getDate() - 7));
      }
      else if($scope.activeBtn == 1){
        $scope.nextday = new Date(date.setMonth(date.getMonth() - 1));
      }
      else{
        $scope.nextday = new Date(date.setFullYear(date.getFullYear() - 1));
      }
      $scope.updateChart($scope.nextday);
    };

    $scope.showWeek = function () {
      $scope.barChart = {};
      $scope.barChart.series = [];
      $scope.barChart.data = [];
      $scope.barChart.labels = [];
      var date = $scope.chartDate;
      var preDate = new Date(date.setDate(date.getDate() - date.getDay()));
      for(i=0; i<7; i++){
        $scope.curDate = new Date(preDate.setDate(date.getDate() + i));
        var curLabel =  weekServiceSmall.week($scope.curDate.getDay());
        $scope.barChart.labels.push([curLabel]);
      }
      $scope.activeBtn = 0;
      $scope.updateChart($scope.chartDate);
    }
    $scope.showWeek();
    $scope.showMonth = function () {
      $scope.barChart.labels = ['JAN','FAB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.activeBtn = 1;
      $scope.updateChart($scope.chartDate);
    }
    $scope.showYear = function () {
      $scope.barChart.labels = ['JAN','FAB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.activeBtn = 2;
      $scope.updateChart($scope.chartDate);
    }

    /*------------------appointment chart ends------------------------*/


    /*------------------practitioner chart starts------------------------*/


    $scope.charttype = 'atype';
    $scope.pieChart = {};

    $scope.pieChart_options = {
      segmentShowStroke : false,
      animationEasing : "linear"
    }

    //get data
    $scope.getPieData = function(){
      var barData = [];
      var labels = []
      $rootScope.cloading = true;
      Data.get('/practitioner_reports?filter_type='+ $scope.charttype).then(function (data) {
        if(!data.code){
          data.series.forEach(function(series){
            labels.push(series.name);
            barData.push(series.data);
          });
          $scope.pieChart.data = barData;
          $scope.pieChart.labels = labels;
        }

        $rootScope.cloading = false;
      });
    }
    $scope.getPieData();

    /*------------------practitioner chart ends------------------------*/

    /*------------------Refrral chart starts------------------------*/


    $scope.refPieChart = {};
    $scope.graphFromDate = {opened: false};
    $scope.graphToDate = {opened: false};
    $scope.openFromDate = function ($event) {
      $scope.graphFromDate.open = true;
    };
    $scope.openToDate = function ($event) {
      $scope.graphToDate.open = true;
    };

    var curDate = new Date();
    $scope.graphfilter = {};
    $scope.graphfilter.from = new Date(curDate.getFullYear(), curDate.getMonth(), 1);
    $scope.graphfilter.to = curDate;

    $scope.refChart_options = {
      segmentShowStroke : false,
      animationEasing : "linear"
    }

    //get data
    $scope.filterGraph = function () {
      var refBarData = [];
      var refLabels = [];
      $rootScope.cloading = true;
      var startDate = $scope.graphfilter.from.getFullYear() +'-'+ ($scope.graphfilter.from.getMonth()+1) +'-'+ $scope.graphfilter.from.getDate();
      var endDate = $scope.graphfilter.to.getFullYear() +'-'+ ($scope.graphfilter.to.getMonth()+1) +'-'+ $scope.graphfilter.to.getDate();
      Data.get("/referral_type_patients/chart_data?start_date=" + startDate + "&end_date=" + endDate).then(function (data) {
        if (!data.code) {
          data.series.forEach(function(series){
            refLabels.push(series.name);
            refBarData.push(series.data);
          });
          $scope.refPieChart.data = refBarData;
          $scope.totalCount = 0;
          for(i=0; i<$scope.refPieChart.data.length; i++){
            $scope.totalCount = $scope.totalCount+$scope.refPieChart.data[i];
          }
          $scope.refPieChart.labels = refLabels;
        }
        $rootScope.cloading = false;
      });
    };
    $scope.filterGraph();

    /*------------------Refrral chart ends------------------------*/

    /*------------------Revenue chart start------------------------*/
    $scope.RevActiveBtn = 0;
    $scope.revType = 'doctor';
    $scope.revChartFilter = '0';
    $scope.revChart = {};

    //to Show Side Date picker
    $scope.showRevDatePicker = false;
    var revPickerStatus = 0;
    $scope.showPicker = function () {
      if (revPickerStatus == 0) {
        $scope.showRevDatePicker = true;
        revPickerStatus = 1;
      }
      else {
        $scope.showRevDatePicker = false;
        revPickerStatus = 0;
      }
    }

    $scope.getRevChartData = function () {
      var revbarData = [];
      var revSeries = []
      var revperiod;
      if ($scope.RevActiveBtn == 0) {
        revperiod = 'week';
      }
      else if($scope.RevActiveBtn == 1){
        revperiod = 'month';
      }
      else{
        revperiod = 'year';
      }
      var revstart_date = $scope.revfirstday.getDate() + '/' + (parseInt($scope.revfirstday.getMonth()) + 1) + '/' + $scope.revfirstday.getFullYear();
      var revend_date = $scope.revlastday.getDate() + '/' + (parseInt($scope.revlastday.getMonth()) + 1) + '/' + $scope.revlastday.getFullYear();
      Data.get('/revenue_reports?filter_type=' + $scope.revType + '&invoice_type=' + $scope.revChartFilter + '&period=' + revperiod +'&start_date=' + revstart_date + '&end_date=' + revend_date).then(function (data) {
        if (!data.code) {
          data.series.forEach(function (series) {
            revSeries.push(series.name);
            revbarData.push(series.data);
          });
          $scope.revChart.data = revbarData;
          var labels_ele = [];
          if($scope.RevActiveBtn == 1){
            for(i=1; i<=$scope.revChart.data[0].length; i++){
              labels_ele.push([i])
            }
            $scope.revChart.labels = labels_ele;
          }
          $scope.revChart.series = revSeries;
        }
        $rootScope.cloading = false;
      });
    }
    $scope.revchartDate = new Date();
    //update chart dates
    $scope.updateRevChart = function (date) {
      $scope.revchartDate = date;
      if ($scope.RevActiveBtn == 0) {
        $scope.revfirstday = new Date(date.setDate(date.getDate() - date.getDay()));
        $scope.revlastday = new Date(date.setDate(date.getDate() - date.getDay() + 6));
      }
      else if ($scope.RevActiveBtn == 1) {
        $scope.revfirstday = new Date(date.getFullYear(), date.getMonth(), 1);
        $scope.revlastday = new Date(date.getFullYear(), date.getMonth()+1, 0);
      }
      else if ($scope.RevActiveBtn == 2) {
        $scope.revfirstday = new Date(date.getFullYear(), 0, 1);
        $scope.revlastday = new Date(date.getFullYear(), 12, 0);
      }
      $scope.showRevDatePicker = false;
      revPickerStatus = 0;
      $scope.getRevChartData();
    }

    //get month name from month number
    $scope.getMonthName = function (date) {
      return monthNameServiceSmall.month(date.getMonth());
    }

    //next Date
    $scope.revnextDate = function (date) {
      if ($scope.RevActiveBtn == 0) {
        $scope.revnextday = new Date(date.setDate(date.getDate() + 7));
      }
      else if($scope.RevActiveBtn == 1){
        $scope.revnextday = new Date(date.setMonth(date.getMonth() + 1));
      }
      else{
        $scope.revnextday = new Date(date.setFullYear(date.getFullYear() + 1));
      }
      $scope.updateRevChart($scope.revnextday);
    }

    //Previous Date
    $scope.revpreDate = function (date) {
      if ($scope.RevActiveBtn == 0) {
        $scope.revnextday = new Date(date.setDate(date.getDate() - 7));
      }
      else if($scope.RevActiveBtn == 1){
        $scope.revnextday = new Date(date.setMonth(date.getMonth() - 1));
      }
      else{
        $scope.revnextday = new Date(date.setFullYear(date.getFullYear() - 1));
      }
      $scope.updateRevChart($scope.revnextday);
    }

    $scope.revshowWeek = function () {
      $scope.revChart.labels = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
      $scope.RevActiveBtn = 0;
      $scope.updateRevChart($scope.revchartDate);
    }
    $scope.revshowWeek();
    $scope.revshowMonth = function () {
      $scope.revChart.labels = [];
      $scope.RevActiveBtn = 1;
      $scope.updateRevChart($scope.revchartDate);
    }
    $scope.revshowYear = function () {
      $scope.revChart.labels = ['JAN','FAB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.RevActiveBtn = 2;
      $scope.updateRevChart($scope.revchartDate);
    }

    /*------------------Revenue chart ends------------------------*/

    /*------------------Daily report start------------------------*/
    //to Show Side Date picker
    $scope.dailyshowDatePicker = false;
    $scope.dailypieChart = {};
    var dailypickerStatus = 0;
    $scope.showDpicker = function () {
      if (dailypickerStatus == 0) {
        $scope.dailyshowDatePicker = true;
        dailypickerStatus = 1;
      }
      else {
        $scope.dailyshowDatePicker = false;
        dailypickerStatus = 0;
      }
    }
    $scope.dontShow = false;
    $scope.todayDate = new Date();
    $scope.dailychartDate = new Date();

    $scope.dailychart_options = {
      segmentShowStroke : false,
      animationEasing : "linear"
    }

    //get all business list
    function getAllBus(){
      Data.get('/daily_reports/locations').then(function(data){
        if (data.locations) {
          $scope.allLoc = data.locations;
          $scope.dailybusiness = $scope.allLoc[0].id;
          $scope.getdailyChartData();
        }
      });
    };
    getAllBus();

    $scope.getdailyChartData = function () {
      var dailybarData = [];
      var dailylabels = []
      $rootScope.cloading = true;
      var calDate = $scope.dailychartDate.getFullYear() +'-'+ ($scope.dailychartDate.getMonth()+1) +'-'+ $scope.dailychartDate.getDate()
      Data.get("/daily_reports/chart_data?bus_id=" + $scope.dailybusiness + "&dt=" + calDate).then(function (data) {
        data.series.forEach(function(series){
          dailylabels.push(series.name);
          dailybarData.push(series.data);
        });
        $scope.dailypieChart.data = dailybarData;
        $scope.dailytotalCount = 0;
        for(i=0; i<$scope.dailypieChart.data.length; i++){
          $scope.dailytotalCount = $scope.dailytotalCount+$scope.dailypieChart.data[i];
        }
        $scope.dailypieChart.labels = dailylabels;
        $rootScope.cloading = false;
      });
    };

    $scope.dailyupdateChart = function(date){
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.dailychartDate = new Date(date.setDate(date.getDate()));
      pickerStatus = 0;
      if($scope.dailychartDate.getDate() == $scope.todayDate.getDate() && $scope.dailychartDate.getMonth() == $scope.todayDate.getMonth() && $scope.dailychartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.dailyshowDatePicker = false;
      $scope.getdailyChartData();
    };


    //Previous Date
    $scope.dailypreDate = function (date) {
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.dailychartDate = new Date(date.setDate(date.getDate() - 1));
      if($scope.dailychartDate.getDate() == $scope.todayDate.getDate() && $scope.dailychartDate.getMonth() == $scope.todayDate.getMonth() && $scope.dailychartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.getdailyChartData();
    };

    //Next Date
    $scope.dailynextDate = function (date) {
      $scope.todayDate = new Date($scope.todayDate.setDate($scope.todayDate.getDate()));
      $scope.dailychartDate = new Date(date.setDate(date.getDate() + 1));
      if($scope.dailychartDate.getDate() == $scope.todayDate.getDate() && $scope.dailychartDate.getMonth() == $scope.todayDate.getMonth() && $scope.dailychartDate.getFullYear() == $scope.todayDate.getFullYear()){
        $scope.dontShow = false;
      }
      else{
        $scope.dontShow = true;
      }
      $scope.getdailyChartData();
    };

    /*------------------Daily report ends------------------------*/

    /*----------------message board Code starts---------------*/
    $scope.newMessage = false;
    $scope.updatePost = false;
    $scope.post = {};

    $scope.newPost = function(){
      $scope.newMessage = true;
      $scope.updatePost = false;
      $scope.post.title = '';
      $scope.post.content = '';
    }

    $scope.cancelNew = function(){
      $scope.newMessage = false;
    }

    //get whole post list
    $rootScope.getPostList = function(){
      $rootScope.cloading = true;
      $http.get('/post').success(function(data){
        $rootScope.cloading = false;
        $scope.postList = data;
      });
    }
    $rootScope.getPostList();

    //save new post
    $scope.savePost = function(data){
      data = {'post' : data}
      if ($scope.updatePost) {
        $http.put('/post/' + $scope.currentPostId ,data).success(function(result){
          $scope.newMessage = false;
          if (result.flag) {
            $rootScope.getPostList();
            $translate('controllerVeriable.postUpdated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.updatePost = false;
          }
          else{
            $modalInstance.dismiss('cancel');
            $rootScope.errors = result.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
      else{
        if (data.post.id) {
          delete data.post.id;
        }
        if (data.post.comments) {
          delete data.post.comments
        }
        $http.post('/post',data).success(function(result){
          $scope.newMessage = false;
          if (result.flag) {
            $rootScope.getPostList();
            $translate('controllerVeriable.newPost').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
          }
          else{
            $rootScope.errors = result.error;
            $rootScope.showMultyErrorToast();
          }
        });
      }
    };

    //save comment
    $scope.saveCommnet = function(data){
      $scope.comment = {'comment' : {'body' : data.postmessage}};
      $http.post('/post/' + data.id + '/comments', $scope.comment).success(function(result){
        if (result.flag) {
          $rootScope.getPostList();
          $translate('controllerVeriable.commentPosted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
        }
        else{
          $rootScope.errors = result.error;
          $rootScope.showMultyErrorToast();
        }
      });
    };

    //Delete post popup
    $scope.openPostPopup = function (id) {
      var modalInstance = $uibModal.open({
        templateUrl: 'DeletePost.html',
        controller: 'postconfirmationCtrl',
        size: 'sm',
        resolve: {
          listId: function () {
            return id;
          }
        }
      });
    };

    //Delete comment popup
    $scope.openCommentPopup = function (post_id, comment_id) {
      var postIds = {'post_id' : post_id , 'comment_id' : comment_id};
      var modalInstance = $uibModal.open({
        templateUrl: 'DeleteComment.html',
        controller: 'commentConfirmationCtrl',
        size: 'sm',
        resolve: {
          postData: function () {
            return postIds;
          }
        }
      });
    };

    $scope.editPost = function(id){
      $scope.currentPostId = id;
      $scope.updatePost = true;
      $scope.newMessage = true;
      $http.get('/post/' + id + '/edit').success(function(data){
        $scope.post = data;
      });
    }

    /*----------------message board Code ends---------------*/

    /*get all businesses locations*/
    function allBusiness(){
      $http.get('/dashboard/locations').success(function(data){
        $scope.allLocations = data;
        $scope.dashboardBusiness = data[0].id;
        $scope.country = data[0].country;
        $scope.city = data[0].city;
        dashboardContent($scope.currentDate);
        appointmentChart(appOffset);
        salesChart(salesOffset);
        appointmentData();
        $scope.app_activity = false;
        $scope.invoice_activity = false;
        $scope.expense_activity = false;
        $scope.sms_activity = true;
        $scope.payment_activity = false;
        appActivity('5');
      });
    };
    allBusiness();

    $scope.crossGraph = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = data;
      $scope.report_options.val = false;
      $scope.report_options = {'report_options' : $scope.report_options};
      $http.post('/dashboard/report_options',$scope.report_options).success(function(result){
        allBusiness();
      });
    };

    $scope.openAppointment = function(data){
      localStorage.setItem('currentAppointment' ,data);
      $state.go('appointment');
    }
  }
]);

/*Confirmation Modal controler*/
app.controller('postconfirmationCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  '$translate',
  'listId',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, $translate, listId) {
    /*close modal*/
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };

    $scope.confirmDelete = function(){
      $http.delete('/post/' + listId).success(function(result){
        if (result.flag) {
          $modalInstance.dismiss('cancel');
          $translate('controllerVeriable.postDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getPostList();
        }
        else{
          $modalInstance.dismiss('cancel');
          $rootScope.errors = result.error;
          $rootScope.showMultyErrorToast();
        }
      })
    }
  }
]);

/*Confirmation Modal controler*/
app.controller('commentConfirmationCtrl', [
  '$rootScope',
  '$scope',
  '$state',
  '$http',
  '$modal',
  '$uibModal',
  '$modalInstance',
  '$translate',
  'postData',
  function ($rootScope, $scope, $state, $http, $modal, $uibModal, $modalInstance, $translate, postData) {
    /*close modal*/
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };

    $scope.deleteComment = function(){
      $http.delete('/post/' + postData.post_id + '/comments/' + postData.comment_id).success(function(result){
        if (result.flag) {
          $modalInstance.dismiss('cancel');
          $translate('controllerVeriable.commentDeleted').then(function (msg) {
            $rootScope.showSimpleToast(msg);
          });
          $rootScope.getPostList();
        }
        else{
          $modalInstance.dismiss('cancel');
          $rootScope.errors = result.error;
          $rootScope.showMultyErrorToast();
        }
      })
    }
  }
]);
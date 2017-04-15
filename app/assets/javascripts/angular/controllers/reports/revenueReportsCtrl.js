app.controller('revenueReportsCtrl', [
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
    $scope.activeBtn = 0;
    $scope.revChart = {};
    $scope.revChart.series = [];
    $scope.revChart.data = [];
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.type = 'doctor';
    $scope.chartFilter = '0';
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
      datasetFill: false,
      scaleShowHorizontalLines: true,
      scaleShowVerticalLines: true,
      legendTemplate: '<ul class="tc-chart-js-legend line-legend"><% for (var i=0; i<datasets.length; i++){%><li><span class="line-legend-icon" style="background-color:<%=datasets[i].strokeColor%>;"></span><span class="line-legend-text" style="color:<%=datasets[i].strokeColor%>"><%if(datasets[i].label){%><%=datasets[i].label%><%}%></span></li><%}%></ul>'
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
    $scope.getChartData = function () {
      var barData = [];
      var Series = []     
      //$rootScope.cloading = true;
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
      Data.get('/revenue_reports?filter_type=' + $scope.type + '&invoice_type=' + $scope.chartFilter + '&period=' + period +'&start_date=' + start_date + '&end_date=' + end_date).then(function (data) {
        if (!data.code) {
          data.series.forEach(function (series) {
            Series.push(series.name);
            barData.push(series.data);
          });
          $scope.revChart.data = barData;
          var labels_ele = [];
          if($scope.activeBtn == 1){
            for(i=1; i<=$scope.revChart.data[0].length; i++){
              labels_ele.push([i])
            }
            $scope.revChart.labels = labels_ele;
          }
          $scope.revChart.series = Series;
        }
        $rootScope.cloading = false;
      });
    }
    $scope.chartDate = new Date();
    //update chart dates
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
      $scope.showDatePicker = false;
      pickerStatus = 0;
      $scope.getChartData();
    }    

    //get month name from month number
    $scope.getMonthName = function (date) {
      return monthNameServiceSmall.month(date.getMonth());
    }    

    //next Date
    $scope.nextDate = function (date) {
      if ($scope.activeBtn == 0) {
        $scope.nextday = new Date(date.setDate(date.getDate() + 7));
      }
      else if($scope.activeBtn == 1){
        $scope.nextday = new Date(date.setMonth(date.getMonth() + 1));
      }
      else{
        $scope.nextday = new Date(date.setFullYear(date.getFullYear() + 1));
      }
      $scope.updateChart($scope.nextday);
    }

    //Previous Date
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
    }    

    $scope.showWeek = function () {
      $scope.revChart.labels = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
      $scope.activeBtn = 0;
      $scope.updateChart($scope.chartDate);
    }
    $scope.showWeek();
    $scope.showMonth = function () {
      $scope.revChart.labels = [];
      $scope.activeBtn = 1;
      $scope.updateChart($scope.chartDate);
    }    
    $scope.showYear = function () {
      $scope.revChart.labels = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.activeBtn = 2;
      $scope.updateChart($scope.chartDate);
    }
       

    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.allLoc = '';
      $scope.allpaymentType = '';
      $scope.allDoc = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/revenue_reports/list/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/revenue_reports/list/pdf.pdf?'
          $scope.printIndication = false;
        }
        else{
          var baseurl = '/revenue_reports/list?'
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
        var j = 0;
        $scope.allFilters.practitioners.forEach(function (doc) {
          if (doc.ischecked) {
            if (j > 0) {
              $scope.allDoc += ',' + doc.id;
            } 
            else if (j == 0) {
              $scope.allDoc += doc.id;
            }
            j++;
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
          baseurl += 'start_date=' + (filter.from.getDate() + '/' + (parseInt(filter.from.getMonth()) + 1) + '/' + filter.from.getFullYear());
        }
        if (filter.to) {
          baseurl += '&end_date=' + (filter.to.getDate() + '/' + (parseInt(filter.to.getMonth()) + 1) + '/' + filter.to.getFullYear());
        }
        if ($scope.allpaymentType != '') {
          baseurl += '&p_type=' + $scope.allpaymentType;
        }
        if ($scope.allDoc != '') {
          baseurl += '&doctor=' + $scope.allDoc;
        }
        if ($scope.allLoc != '') {
          baseurl += '&loc=' + $scope.allLoc;
        }
        return resolve(baseurl)
      });
    }
    $scope.allRevenue = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allRevenueList = data.listing;
          if ($scope.allRevenueList.length == 0) {
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          //default check checkboxes
          var docs = $scope.allDoc.split(',');
          for (i = 0; i < docs.length; i++) {
            $scope.allFilters.practitioners.forEach(function (doctor) {
              if (doctor.id == parseInt(docs[i])) {
                doctor.ischecked = true;
              }
            });
          }
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
        });
      })
    }

    //onload table content data
    $scope.allRevenueData = function () {
      $rootScope.cloading = true;
      Data.get('/revenue_reports/list').then(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.allFilters = data;
          $scope.allRevenueList = data.listing;
          console.log('List here: ', $scope.allFilters);
          if ($scope.allRevenueList.length == 0) {
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
    $scope.allRevenueData();

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
        $scope.addDash.revenue = data.revenue;
      });
    };
    getAddDash();

    $scope.addToDashboard = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = 'revenue';
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

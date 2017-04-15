app.controller('reportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$compile',
  'DTOptionsBuilder', 
  'DTColumnBuilder',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $compile, DTOptionsBuilder, DTColumnBuilder) {

  }
]);
app.controller('reportsModuleCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$http',
  'DTOptionsBuilder',
  'DTColumnBuilder',
  'DTColumnDefBuilder',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $http, DTOptionsBuilder, DTColumnBuilder, DTColumnDefBuilder, $state) {
    $scope.activeBtn = 0;
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.type = 'summary';
    $scope.noData = false;

    /*$scope.dtColumnDefs = [  
      DTColumnDefBuilder.newColumnDef([0]).withOption('type', 'date')
    ];  */  
    
    $scope.dtOptions = DTOptionsBuilder.newOptions().withPaginationType('full_numbers')
          
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    //get appointment list
    function getAppointmentsList() {
      Data.get('/settings/appointment_type').then(function (list) {
        $scope.AppointmentTypeList = list;
      });
    }
    getAppointmentsList();
    //get businesses list
    function getBusinessList() {
      Data.get('/settings/business').then(function (results) {
        $scope.businessList = results;
      });
    }
    getBusinessList();
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
      var Series = [];   
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

    //Previous Date
    $scope.preDate = function (date) {
      if ($scope.activeBtn == 0) {
        $scope.nextday = new Date(date.setDate(date.getDate() - 7));
        /*$scope.chartDate = $scope.nextday;
        $scope.showWeek();*/
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
      $scope.barChart.labels = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.activeBtn = 1;
      $scope.updateChart($scope.chartDate);
    }    
    $scope.showYear = function () {
      $scope.barChart.labels = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      $scope.activeBtn = 2;
      $scope.updateChart($scope.chartDate);
    }

    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.allLoc = '';
      $scope.allSer = '';
      $scope.allDoc = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/reports/appointments/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/reports/appointments/generate_pdf.pdf?'
          $scope.printIndication = false; 
        }
        else{
          var baseurl = '/reports/appointments?'
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
        $scope.allFilters.services.forEach(function (ser) {
          if (ser.ischecked) {
            if (k > 0) {
              $scope.allSer += ',' + ser.id;
            } 
            else if (k == 0) {
              $scope.allSer += ser.id;
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
        if (filter.missedApp) {
          baseurl += '&miss_appnt=' + filter.missedApp;
        }
        if ($scope.allSer != '') {
          baseurl += '&service=' + $scope.allSer;
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
    $scope.allAppointments = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allAppointmentsList = data.appointments_list_reports;
          if($scope.allAppointmentsList.length == 0){
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
          var servs = $scope.allSer.split(',');
          for (k = 0; k < servs.length; k++) {
            $scope.allFilters.services.forEach(function (services) {
              if (services.id == parseInt(servs[k])) {
                services.ischecked = true;
              }
            });
          }
          $rootScope.cloading = false;
        });
      })
    }

    //onload table content data
    $scope.allAppointmentsData = function () {
      $rootScope.cloading = true;
      Data.get('/reports/appointments').then(function (data) {
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.allFilters = data;
          $scope.allAppointmentsList = data.appointments_list_reports;
          if($scope.allAppointmentsList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false; 
          }
          $scope.filter.from = '';
          $scope.filter.to = '';
          $scope.filter.missedApp = false;
        }
        
        $rootScope.cloading = false;
      });
    }
    $scope.allAppointmentsData();

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
        $scope.addDash.appnt = data.appnt;
      });
    };
    getAddDash();

    $scope.addToDashboard = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = 'appnt';
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

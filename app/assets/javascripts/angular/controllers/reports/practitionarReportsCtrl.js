app.controller('practitionarReportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  '$http',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, $http, $state) {
    $scope.pieChart = {};
    $scope.pieChart.labels = [];
    $scope.pieChart.data = [];
    $scope.noData = false; 
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.type = 'atype';
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    $scope.chart_options = {
      segmentShowStroke : false,
      animationEasing : "linear"
      //legendTemplate : '<ul class="tc-chart-js-legend line-legend"><% for (var i=0; i<datasets.length; i++){%><li><span class="line-legend-icon" style="background-color:<%=datasets[i].strokeColor%>;"></span><span class="line-legend-text" style="color:<%=datasets[i].strokeColor%>"><%if(datasets[i].label){%><%=datasets[i].label%><%}%></span></li><%}%></ul>'
    }
    $scope.stopEvent = function (events) {
      events.stopPropagation();
    }
    //get data
    $scope.getPieData = function(){
      var barData = [];
      var labels = []
      $rootScope.cloading = true;
      Data.get('/practitioner_reports?filter_type='+ $scope.type).then(function (data) {
        console.log(data)
        if (!data.code) {
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

    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.allLoc = '';
      $scope.allSerType = '';
      $scope.allApp = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/practitioner_reports/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = ' /practitioner_reports/generate_pdf.pdf?'
          $scope.printIndication = false;
        }
        else{
          var baseurl = '/practitioner_reports/list?'
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
        $scope.allFilters.service_items.forEach(function (doc) {
          if (doc.ischecked) {
            if (j > 0) {
              $scope.allSerType += ',' + doc.id;
            } 
            else if (j == 0) {
              $scope.allSerType += doc.id;
            }
            j++;
          }
        });
        var k = 0;
        $scope.allFilters.services.forEach(function (ser) {
          if (ser.ischecked) {
            if (k > 0) {
              $scope.allApp += ',' + ser.id;
            } 
            else if (k == 0) {
              $scope.allApp += ser.id;
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
        if ($scope.allSerType != '') {
          baseurl += '&item=' + $scope.allSerType;
        }
        if ($scope.allApp != '') {
          baseurl += '&service=' + $scope.allApp;
        }
        if ($scope.allLoc != '') {
          baseurl += '&loc=' + $scope.allLoc;
        }
        return resolve(baseurl)
      });
    }
    $scope.filterPractitionarsData = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allPractitionarsList = data.doctors_listing_info;
          if($scope.allPractitionarsList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false; 
          }
          
          //default check checkboxes
          var apps = $scope.allApp.split(',');
          for (i = 0; i < apps.length; i++) {
            $scope.allFilters.services.forEach(function (app) {
              if (app.id == parseInt(apps[i])) {
                app.ischecked = true;
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
          var servs = $scope.allSerType.split(',');
          for (k = 0; k < servs.length; k++) {
            $scope.allFilters.service_items.forEach(function (services_item) {
              if (services_item.id == parseInt(servs[k])) {
                services_item.ischecked = true;
              }
            });
          }
          $rootScope.cloading = false;
        });
      })
    }

    //onload table content data
    $scope.allPractitionarsData = function () {
      $rootScope.cloading = true;
      Data.get('/practitioner_reports/list').then(function (data) {
        if (data.doctors_listing_info) {
          $scope.allFilters = data;
          $scope.allPractitionarsList = data.doctors_listing_info;
          if($scope.allPractitionarsList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false; 
          }
          $scope.filter.from = '';
          $scope.filter.to = '';
        }
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        
        $rootScope.cloading = false;
      });
    }
    $scope.allPractitionarsData();

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
        $scope.addDash.doctor = data.doctor;
      });
    };
    getAddDash();

    $scope.addToDashboard = function(data){
      $scope.report_options = {};
      $scope.report_options.obj = 'dc';
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
}]);
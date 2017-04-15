app.controller('recallPatientReportsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'monthNameService',
  '$state',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, monthNameService, $state) {
    $scope.activeWeek = false;
    $scope.fromDate = {opened: false};
    $scope.toDate = {opened: false};
    $scope.noData = false;
    $scope.noBirthday = false;
    //set current month in dropdown
    $scope.monthName = ((new Date()).getMonth()+1).toString();
    $scope.showMonth = $scope.monthName;
    $scope.openFrom = function ($event) {
      $scope.fromDate.opened = true;
    };
    $scope.openTo = function ($event) {
      $scope.toDate.opened = true;
    };
    //stop dropdown's auto close event
    $scope.stopEvent = function (events) {
      events.stopPropagation();
    }
    //get month name from month no
    $scope.getMonthName = function(monthNo){
      $scope.curMonth = monthNameService.month(parseInt(monthNo)-1);
    }
    $scope.getMonthName($scope.showMonth);

    //--------------------------- filters --------------------------//
    //get all Appointments
    $scope.filter = {}
    function buildFilters() {
      $scope.allRecalls = '';
      $scope.allDoc = '';
      return $q(function (resolve, reject) {
        if ($scope.exportIndication == true) {
          var baseurl = '/patient_reports/recall/list/export.csv?'
          $scope.exportIndication = false;
        }
        else if($scope.printIndication == true){
          var baseurl = '/patient_reports/recall/list/pdf.pdf?'
          $scope.printIndication = false; 
        }
        else{
          var baseurl = '/patient_reports/recall/list?'
        }
        var filter = $scope.filter;
        var i = 0;
        $scope.allFilters.recalls.forEach(function (loc) {
          if (loc.ischecked) {
            if (i > 0) {
              $scope.allRecalls += ',' + loc.id;
            } 
            else if (i == 0) {
              $scope.allRecalls += loc.id;
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
        if (filter.from) {
          baseurl += 'start_date=' + (filter.from.getDate() + '/' + (parseInt(filter.from.getMonth()) + 1) + '/' + filter.from.getFullYear());
        }
        if (filter.to) {
          baseurl += '&end_date=' + (filter.to.getDate() + '/' + (parseInt(filter.to.getMonth()) + 1) + '/' + filter.to.getFullYear());
        }
        if ($scope.allDoc != '') {
          baseurl += '&doctor=' + $scope.allDoc;
        }
        if ($scope.allRecalls != '') {
          baseurl += '&recall_id=' + $scope.allRecalls;
        }
        return resolve(baseurl)
      });
    }
    $scope.allpatients = function () {
      $rootScope.cloading = true;
      var promise = buildFilters();
      promise.then(function (results) {
        Data.get(results).then(function (data) {
          $scope.allFilters = data;
          $scope.allpatientsList = data.listing;
          if($scope.allpatientsList.length == 0){
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
          var locs = $scope.allRecalls.split(',');
          for (j = 0; j < locs.length; j++) {
            $scope.allFilters.recalls.forEach(function (locations) {
              if (locations.id == parseInt(locs[j])) {
                locations.ischecked = true;
              }
            });
          }
          $rootScope.cloading = false;
        });
      })
    }

    //onload table content data
    $scope.allPatientsData = function () {
      $rootScope.cloading = true;
      Data.get('/patient_reports/recall/list').then(function (data) {
        console.log(data);
        if (data.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
        else{
          $scope.allFilters = data;
          $scope.allpatientsList = data.listing;
          if($scope.allpatientsList.length == 0){
            $scope.noData = true;
          }
          else{
            $scope.noData = false;
          }
          $scope.filter.from = '';
          $scope.filter.to = '';
          $scope.filter.recalls = false;
        }
        $rootScope.cloading = false;
      });
    }
    $scope.allPatientsData();

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
    
    
  }
]);

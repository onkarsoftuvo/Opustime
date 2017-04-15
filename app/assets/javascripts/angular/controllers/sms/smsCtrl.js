app.controller('smsCtrl', [
  '$rootScope',
  '$scope',
  'Data',
  '$translate',
  'monthNameServiceSmall',
  '$q',
  'weekServiceSmall',
  '$http',
  '$state',
  '$q',
  'pageService',
  function ($rootScope, $scope, Data, $translate, monthNameServiceSmall, $q, weekServiceSmall, $http, $state, $q, pageService) {
    
    init();

    function init(){
      $scope.pagingData = {};
      $scope.pagingData.fromFilter = '';
      $scope.pagingData.toFilter = '';
      $scope.pagingData.user_id = null;
      $scope.pagingData.Page = 1;
      $scope.pagingData.TotalItems = 0;
      $scope.pagingData.PageSize = 30;
      $scope.showGrid = false;
    }

    //$scope.filter = {};
    $scope.from = {opened: false};
    $scope.to = {opened: false};
    $scope.recall = {opened: false};
    $scope.recall = {opened: false};
    $scope.refer = {opened: false};
    $scope.birth = {opened: false};
    $scope.birthdayDate = new Date();
    $scope.recallDate = new Date();
    $scope.referDate = new Date();

    $scope.openFrom = function ($event) {
      $scope.from.opened = true;
    };

    $scope.openTo = function ($event) {
      $scope.to.opened = true;
    };

    $scope.openRecall = function ($event) {
      $scope.recall.opened = true;
    };

    $scope.openBirth = function ($event) {
      $scope.birth.opened = true;
    };

    $scope.openRefer = function ($event) {
      $scope.refer.opened = true;
    };

    var conRadio = 0;
    $scope.radioCon = false;
    $scope.patientFilter = 'appnt';
    $scope.contactRadio = function(){
      $scope.radioPatient = false;
      $scope.radioBirth = false;
      $scope.radioRecall = false;
      $scope.radioRefer = false;
      patientCon = 0;
      recallCon = 0;
      birthCon = 0;
      referCon = 0;
      if (conRadio == 0) {
        $scope.filterSMS($scope.pagingData);
        $scope.radioCon = true;
        conRadio = 1;
      }
      else{
        $scope.radioCon = false;
        conRadio = 0; 
      }
    }

    $scope.stopEvent = function (events) {
      events.stopPropagation();
    }
    

    var patientCon = 1;
    $scope.radioPatient = true;
    $scope.patientRadio = function(){
      $scope.radioCon = false;
      $scope.radioBirth = false;
      $scope.radioRecall = false;
      $scope.radioRefer = false;
      conRadio = 0; 
      recallCon = 0;
      birthCon = 0;
      referCon = 0;
      if (patientCon == 0) {
        $scope.filterSMS($scope.pagingData);
        $scope.radioPatient = true;
        patientCon = 1;
      }
      else{
        $scope.radioPatient = false;
        patientCon = 0; 
      }
    }

    var birthCon = 0;
    $scope.radioBirth = false;
    $scope.birthdayRadio = function(){
      $scope.radioCon = false;
      $scope.radioRecall = false;
      $scope.radioPatient = false;
      $scope.radioRefer = false;
      conRadio = 0; 
      patientCon = 0;
      recallCon = 0;
      referCon = 0
      if (birthCon == 0) {
        $scope.filterSMS($scope.pagingData);
        $scope.radioBirth = true;
        birthCon = 1;
      }
      else{
        $scope.radioBirth = false;
        birthCon = 0; 
      }
    }

    var recallCon = 0;
    $scope.radioRecall = false;
    $scope.recallRadio = function(){
      $scope.radioCon = false;
      $scope.radioBirth = false;
      $scope.radioPatient = false;
      $scope.radioRefer = false;
      conRadio = 0; 
      patientCon = 0;
      birthCon = 0;
      referCon = 0
      if (recallCon == 0) {
        $scope.filterSMS($scope.pagingData);
        $scope.radioRecall = true;
        recallCon = 1;
      }
      else{
        $scope.radioRecall = false;
        recallCon = 0; 
      }
    }

    var referCon = 0;
    $scope.radioRecall = false;
    $scope.referresRadio = function(){
      $scope.radioCon = false;
      $scope.radioBirth = false;
      $scope.radioPatient = false;
      $scope.radioRecall = false;
      conRadio = 0; 
      patientCon = 0;
      birthCon = 0;
      recallCon = 0
      if (referCon == 0) {
        $scope.filterSMS($scope.pagingData);
        $scope.radioRefer = true;
        referCon = 1;
      }
      else{
        $scope.radioRefer = false;
        referCon = 0; 
      }
    }

    $scope.usersRadio = function(){
      $scope.filterSMS($scope.pagingData);
      $scope.radioCon = false;
      conRadio = 0; 
      $scope.radioPatient = false;
      patientCon = 0;
    }



    function allAppFilters(){
      $http.get(' /sms_center/filters').success(function(data){
        $scope.appFilter = data;
      })
    }
    allAppFilters()

    $scope.filter = 'patient';
    $scope.upcoming = false;
    $scope.outstanding = false;
    $scope.credit = false;
    $scope.standard = false;
    $scope.doctor = false;
    $scope.third_party = false;

    $scope.allFilters = {};
    $scope.fromDate = null;
    $scope.toDate = null;
    $scope.business = '';
    $scope.practi = '';
    $scope.services = '';

    $scope.filterSMS = function(pagingData){
      $scope.smsList = [];
      $scope.selectEach = false;
      $rootScope.cloading = true;
      $scope.allFilters.obj_type = $scope.filter;
      if ($scope.filter == 'patient') {
        $scope.allFilters.filter_type = $scope.patientFilter;
        if($scope.patientFilter == 'appnt'){
          $scope.allFilters.filters = {};
          $scope.allFilters.filters.st_date = $scope.fromDate;
          $scope.allFilters.filters.end_date = $scope.toDate;
          if ($scope.allFilters.filterDate) {
            delete $scope.allFilters.filterDate;
          }
          $scope.allFilters.filters.bs_id = '';
          var i = 0;
          $scope.appFilter.businesses.forEach(function (bus) {
            if (bus.ischecked) {
              if (i > 0) {
                $scope.allFilters.filters.bs_id += ',' + bus.id;
              } 
              else if (i == 0) {
                $scope.allFilters.filters.bs_id += bus.id;
              }
              i++;
            }
          });
          $scope.allFilters.filters.doctor = '';
          var j = 0;
          $scope.appFilter.doctors.forEach(function (doc) {
            if (doc.ischecked) {
              if (j > 0) {
                $scope.allFilters.filters.doctor += ',' + doc.id;
              } 
              else if (j == 0) {
                $scope.allFilters.filters.doctor += doc.id;
              }
              j++;
            }
          });
          $scope.allFilters.filters.service = '';
          var k = 0;
          $scope.appFilter.services.forEach(function (ser) {
            if (ser.ischecked) {
              if (k > 0) {
                $scope.allFilters.filters.service += ',' + ser.id;
              } 
              else if (k == 0) {
                $scope.allFilters.filters.service += ser.id;
              }
              k++;
            }
          });
          $scope.allFilters.filters.upcoming = $scope.upcoming;
        }
        else{
          $scope.allFilters.filters = {};
          $scope.allFilters.filters.outstanding = $scope.outstanding;
          $scope.allFilters.filters.credit = $scope.credit;
        }
      }
      else if($scope.filter == 'contact'){
        delete $scope.allFilters.filter_type;
        $scope.allFilters.filters = {};
        $scope.allFilters.filters.standard = $scope.standard;
        $scope.allFilters.filters.doctor = $scope.doctor;
        $scope.allFilters.filters.third_party = $scope.third_party;
        if ($scope.allFilters.filterDate) {
          delete $scope.allFilters.filterDate;
        }
      }
      else if($scope.filter == 'user'){
        delete $scope.allFilters.filter_type;
        delete $scope.allFilters.filters;
        if ($scope.allFilters.filterDate) {
          delete $scope.allFilters.filterDate;
        }
      }
      else if($scope.filter == 'birthdays'){
        delete $scope.allFilters.filter_type;
        delete $scope.allFilters.filters;
        $scope.allFilters.filterDate = $scope.birthdayDate;
      }
      else if($scope.filter == 'recalls'){
        delete $scope.allFilters.filter_type;
        delete $scope.allFilters.filters;
        $scope.allFilters.filterDate = $scope.recallDate;
      }
      else if($scope.filter == 'refers'){
        delete $scope.allFilters.filter_type;
        delete $scope.allFilters.filters;
        $scope.allFilters.filterDate = $scope.referDate;
      }
      $http.post('/sms_center/get_data?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page, $scope.allFilters).success(function(result){
        if(result.objects.length != 0){
          $rootScope.cloading = false;
          $scope.smsList = result.objects;
          $scope.pagingData.TotalItems = result.total;
          $scope.showGrid = true;
          $scope.noRecordFount = false;
          setPager();
        }else{
          $rootScope.cloading = false;
          $scope.showGrid = false;
          $scope.noRecordFount = true;
        }
      });

      // $http.post('/sms_center/get_data', $scope.allFilters).success(function(result){
      //   $rootScope.cloading = false;
      //   $scope.smsList = result.objects;
      // });
    };

    // $scope.getSMS = function(pagingData){
    //   console.log('Here the pagination: ', pagingData, $scope.allFilters);
    //   $rootScope.cloading = true;
    //   $scope.allFilters.obj_type = $scope.filter;
    //   if ($scope.filter == 'patient') {
    //     $scope.allFilters.filter_type = $scope.patientFilter;
    //     if($scope.patientFilter == 'appnt'){
    //       $scope.allFilters.filters = {};
    //       $scope.allFilters.filters.st_date = $scope.fromDate;
    //       $scope.allFilters.filters.end_date = $scope.toDate;
    //       $scope.allFilters.filters.bs_id = '';
    //       $scope.allFilters.filters.doctor = '';
    //       $scope.allFilters.filters.service = '';
    //       $scope.allFilters.filters.upcoming = $scope.upcoming;
    //     }
    //     else{
    //       $scope.allFilters.filters = {};
    //       $scope.allFilters.filters.outstanding = $scope.outstanding;
    //       $scope.allFilters.filters.credit = $scope.credit;
    //     }
    //   }
    //   else if($scope.filter == 'contact'){
    //     delete $scope.allFilters.filter_type;
    //     $scope.allFilters.filters = {};
    //     $scope.allFilters.filters.standard = $scope.standard;
    //     $scope.allFilters.filters.doctor = $scope.doctor;
    //     $scope.allFilters.filters.third_party = $scope.third_party;
    //   }
    //   else if($scope.filter == 'user'){
    //     delete $scope.allFilters.filter_type;
    //     delete $scope.allFilters.filters;
    //   }
    //   // if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id == null) {
    //   //   obj = $http.get('/sms_center/get_data?per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
    //   // }else if(pagingData.toFilter =="" && pagingData.fromFilter == "" && pagingData.user_id != null){
    //   //   obj = $http.get('/sms_center/get_data?per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page + '&user_id=' + pagingData.user_id);
    //   // }else if(pagingData.toFilter !="" && pagingData.fromFilter != "" && pagingData.user_id == null){
    //   //   obj = $http.get('/sms_center/get_data?per_page=' + $scope.pagingData.fromFilter + '&end_date=' + $scope.pagingData.toFilter + '&per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page);
    //   // }else{
    //   //   obj = $http.get('/sms_center/get_data?per_page=' + $scope.pagingData.fromFilter + '&end_date=' + $scope.pagingData.toFilter + '&per_page=' + $scope.pagingData.PageSize + '&page=' + $scope.pagingData.Page + '&user_id=' + pagingData.user_id);
    //   // }

    //   $http.post('/sms_center/get_data?per_page=' + pagingData.PageSize + '&page=' + pagingData.Page, $scope.allFilters).success(function(result){
    //     console.log('Here the ouput: ', result);
    //     if(result.objects.length != 0){
    //       $scope.showGrid = true;
    //       $rootScope.cloading = false;
    //       $scope.smsList = result.objects;
    //       $scope.pagingData.TotalItems = result.pagination.total;
    //       setPager();
    //     }else{
    //       $scope.showGrid = false;
    //     }
    //   });
    // };
    
    function getPermissions(){
      return  $q(function (resolve, reject) {
        $http.get('/communications/check/security_roles').success(function(data){
          console.log(data);
          if (!data.view) {
            $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
            $state.go('dashboard')  
          }
          else{
            $scope.filterSMS($scope.pagingData);
          }
          resolve();
        });
      });
    }
    $scope.hitCom = getPermissions();

    $scope.clearFilter = function(){
      $scope.filter = 'patient';
      $scope.patientFilter = 'appnt';
      $scope.upcoming = false;
      $scope.outstanding = false;
      $scope.credit = false;
      $scope.standard = false;
      $scope.doctor = false;
      $scope.third_party = false;
      $scope.fromDate = null;
      $scope.toDate = null;
      $scope.business = '';
      $scope.practi = '';
      $scope.services = '';
      $scope.appFilter.businesses.forEach(function (bus) {
        bus.ischecked = false;
      });
      $scope.appFilter.doctors.forEach(function (doc) {
        doc.ischecked = false;
      });
      $scope.appFilter.services.forEach(function (ser) {
        ser.ischecked = false;
      });

      $scope.filterSMS($scope.pagingData);
    }

    $scope.selectAll = function(){
      console.log($scope.smsList)
      if($scope.selectEach){
        $scope.smsList.forEach(function(con){
          if(!con.contact_fourth && !con.contact_one && !con.contact_second && !con.contact_third){
            con.isSelect = false;
          }
          else{
            con.isSelect = true;
          }
        });
      }
      else{
        $scope.smsList.forEach(function(con){
          con.isSelect = false;
        }) 
      }
    }

    $scope.sendSMS = function(){
      var smsId = [];
      var recallId = [];
      $scope.smsList.forEach(function(allSms){
        if (allSms.isSelect) {
          smsId.push(allSms.id)
          recallId.push(allSms.recall_id)
        }
      });
      localStorage.setItem('recallId', recallId);
      localStorage.setItem('contactId', smsId);
      localStorage.setItem('obj_type', $scope.filter);
      localStorage.setItem('filter_date', $scope.allFilters.filterDate);
      $state.go('sms.send')
    }

    $scope.goToPatient = function(id){
      $state.go('patient-detail',{'patient_id' : id});
    }

    //pagination code---------------------------------------------------

    $scope.$on('PagerInitialized', function(event, pageData) {
      $scope.pagingData = pageData;
    });

    $scope.$on('PagerSelectPage', function(event, pagingData) {
      $scope.pagingData = pagingData;
      $scope.filterSMS($scope.pagingData);
    });

    function setPager() {
      pageService.setPaging($scope.pagingData);
    };
    
    //pagination ends here----------------------------------------------------
  }
]);

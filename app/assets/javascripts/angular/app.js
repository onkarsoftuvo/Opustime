var app = angular.module('Zuluapp', [
  'ui.router',
  'ngAnimate',
  'ui.bootstrap',
  'oc.lazyLoad',
  'angular-datepicker',
  'ngScrollbars',
  'ngFileUpload',
  'ngMaterial',
  'ui.router.stateHelper',
  'textAngular',
  'ui.tree',
  'ngCookies',
  'pascalprecht.translate',
  'ui.calendar',
  'chart.js',
  'nvd3',
  'datatables',
  'ngResource',
  'credit-cards',
  'bw.paging',
]);

app.controller('MainCntl', [
  '$scope',
  '$http',
  '$state',
  function ($scope, $http, $state) {
    //$rootScope.themeClass = 'blue_theme';
    $scope.notificationsData = [];
    $scope.notiLoad = false;
    $scope.nextNotiHit = 1;
    $scope.no_notification = false;

    $scope.getNotifications = function(page_no){
      $scope.no_notification = false;
      console.log(page_no)
      if (page_no == 1) {
        $scope.notificationsData = [];
        console.log(page_no)
      }
      if (page_no != null) {
        $scope.notiLoad = true;
        $http.get('/notifications?page_no='+page_no).success(function(data){
          $scope.nextNotiHit = data.next_page;

          $scope.notiLoad = false;
          $scope.notificationsData = $scope.notificationsData.concat(data.data);
          if ($scope.notificationsData.length == 0) {
            $scope.no_notification = true;
          }
          else{
           $scope.no_notification = false; 
          }
        })
      }
    }
    $scope.goToPatient = function(id, patient_id, patient_no){
      $http.get('/notifications/open?id='+id).success(function(data){
        console.log(data);
        $state.go('patient-detail.sendSms', {'phone_no' : patient_no, 'patient_id' : patient_id});
      });
    }
    $scope.goToOther = function(id, log_id, type, no){
      $http.get('/notifications/open?id='+id).success(function(data){
        console.log(data);
        if (type == 'User') {+
          $state.go('smsLogs.Userview', {'userType' : log_id});
        }
        else if(type == 'Contact'){
          $state.go('smsLogs.Contactview', {'contactType' : log_id});
        }
        else if(type == null){
          $state.go('smsLogs.unknownview', {'unknownNo' : no});
        }
      });
      
    }

    $scope.totalbalance = function(){
      console.log('=========')
      $http.get('/settings/subscription/auto_credit').success(function(response){
        console.log(response);
        $scope.total_balance = response.balance;
      })
    }
  }
]);

app.run(function ($rootScope, $location, $state, $stateParams, $http, Auth, $mdToast, toplink, lazyload) {
  $rootScope.$on('$stateChangeStart', function (event, next, current, toState) {
    $rootScope.authenticated = false;
    //console.log(window.navigator.language);
    $rootScope.cloading = true;
    //Hit Api for Roles And give page autorization
    Auth.getsession().then(function (results) {
      if (results.flag == true) {
        $rootScope.User_id = results.session_id;
        localStorage.setItem('currentUser', $rootScope.User_id);
        $rootScope.name = results.user_name;
        $rootScope.comp_id = results.comp_id;
       
        $rootScope.isLoggedIn = true;
        if (results.user_name == '@@@') {
          location.href = '#!/signup/' + results.comp_id;
          $rootScope.isLoggedIn = false;
        }
        else if (next.data.authRequire == false && results.user_name != '@@@') {
          /*$rootScope.isLoggedIn = true;
          $state.go('dashboard');*/
          if (results.is_2factor_auth_enabled && results.google_authenticator_session == true) {
            $rootScope.isLoggedIn = true;
            $state.go('dashboard');
          }
          else if(results.is_2factor_auth_enabled && !results.google_authenticator_session){
            $rootScope.isLoggedIn = false;
            $state.go('loginConfirm',{'user_id':results.session_id});
          }
          else if(!results.is_2factor_auth_enabled && !results.google_authenticator_session || results.google_authenticator_session){
            $rootScope.isLoggedIn = true;
            $state.go('dashboard');
          }
          /*else{
            $rootScope.isLoggedIn = true;
            $state.go('dashboard');
          }*/
        }
        else if(next.data.authRequire == true && results.is_2factor_auth_enabled && !results.google_authenticator_session){
          $rootScope.isLoggedIn = false;
          $state.go('loginConfirm',{'user_id':results.session_id});
        }
      }
      else {
        $rootScope.isLoggedIn = false;
        if (next.data.authRequire == false) {
          return
        }
        else {
          $state.go('login_first');
        }
      }
    });

    Auth.getAuthorised().then(function (response) {
      $rootScope.DashboardLinks = response;
    });
    $rootScope.logout = function () {
      $http.get('/signed_out').success(function (response) {
        $state.go('login_first');
      });
    }
    $rootScope.subscr = function(){
      $http.get('/settings/subscription/state').success(function(results){
        $rootScope.subsData = results[0];
        $rootScope.is_trial = results[0].is_trial;
        $rootScope.is_subsc = results[0].is_subscribed;
       if($rootScope.is_trial == false && $rootScope.is_subsc == true || $rootScope.is_trial == true && $rootScope.is_subsc == false){
          $rootScope.subscription_status = true;
          $rootScope.subscript = false;
          $rootScope.dashboardStatus=false;
          $rootScope.dashSubscript_status = true;
        }
       else if($rootScope.is_trial == false && $rootScope.is_subsc == false){
          $rootScope.subscription_status = true;
          $rootScope.subscript = true;
          $rootScope.dashboardStatus = true;
          $rootScope.dashSubscript_status = false; 
          var path = $location.path();
          if(path !== '/settings/subscription' && path !== '/dashboard'){
            $state.go('dashboard');
          }
        }
        else {
          console.log("not done");
        }
          console.log('subscription_status ', $rootScope.subscription_status);
      })
    }
    $rootScope.subscr();
    $rootScope.showSimpleToast = function (content) {
      $mdToast.show($mdToast.simple().content(content).position('bottom left').hideDelay(5000)
      );
    };
    $rootScope.showErrorToast = function (content) {
      $mdToast.show($mdToast.simple().content(content).theme('error-toast-single').position('bottom left').hideDelay(6000)
      );
    };
    $rootScope.showMultyErrorToast = function (content) {
      $mdToast.show({
        templateUrl: 'assets/angular/toast-template.html',
        hideDelay: 6000,
        position: 'bottom left'
      });
    };
    $rootScope.range = function (min, max, step) {
      step = step || 1;
      var input = [
      ];
      for (var i = min; i <= max; i += step) input.push(i);
      return input;
    };
  });
  $rootScope.$on('$stateChangeSuccess', function (event, next, current) {
    $rootScope.$watch(function () {
      $rootScope.$broadcast('rebuild:me');
    });
    $rootScope.cloading = false;
  });
  $rootScope.ScrollPer = 0;
  $rootScope.lazyloadConfig = lazyload.config();
  $rootScope.$state = $state;
  $rootScope.$stateParams = $stateParams;
  //dynamic atendee patient/member/client
  $rootScope.translationData = {};
  $rootScope.getAtendee = function () {
    $http.get('/settings/account/attendee').success(function (data) {
      $rootScope.commonData = data;
      if(data.logo_url == '/logos/original/missing.png'){
        $rootScope.businessLogo = null;
      }else{
        $rootScope.businessLogo = data.logo_url;        
      }
      if (data.theme_name) {
        $rootScope.themeClass = data.theme_name;
      } 
      else {
        $rootScope.themeClass = 'blue_theme';
      }
      console.log($rootScope.themeClass);
      $rootScope.translationData.attendeeS = data.attendee_name;
      if (data.attendee_name == 'patients') {
        $rootScope.translationData.attendee = 'client';
      } 
      else if (data.attendee_name == 'members') {
        $rootScope.translationData.attendee = 'member';
      } 
      else if (data.attendee_name == 'clients') {
        $rootScope.translationData.attendee = 'client';
      }
      console.log($rootScope.translationData);
    });
  };
  $rootScope.getAtendee();
});

app.filter('capitalize', function () {
  return function (input, all) {
    var reg = (all) ? /([^\W_]+[^\s-]*) */g : /([^\W_]+[^\s-]*)/;
    return (!!input) ? input.replace(reg, function (txt) {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    })  : '';
  }
});

app.filter('parseUrlFilter', function () {
  var urlPattern = /(http|ftp|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:\/~+#-]*[\w@?^=%&amp;\/~+#-])?/gi;
  return function (text, target, otherProp) {
    if (text) {
      return text.replace(urlPattern, '<a target="' + target + '" href="$&">$&</a>');
    }
  };
});
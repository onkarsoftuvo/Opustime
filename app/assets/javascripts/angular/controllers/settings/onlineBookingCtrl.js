app.controller('onlineBookingCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  'Data',
  'Upload',
  '$translate',
  '$state',
  function ($scope, $rootScope, $http, Data, Upload, $translate, $state) {
    $scope.booking_info = '';
    //Get Booking Information 
    $scope.bookingData = function () {
      Data.get('/settings/online_booking').then(function (results) {
        if (results.code) {
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        } 
        else {
          $scope.booking_info = results;
        }
      });
    }
    function getFacebookPageId() {
      Data.get('/settings/facebook/pages').then(function (results) {
        if (!results.code) {
          $scope.FacebookPageId = results;
        }
      });
    }
    getFacebookPageId()
    $scope.bookingData();
    //Update Booking Data
    $scope.updateBooking = function (file, data) {
      $rootScope.cloading = true;
      $http.put(' /settings/online_booking/' + data.id, data).success(function (results) {
        if (results.error) {
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          $rootScope.cloading = false;
        } 
        else if (file) {
          //file upload 
          if (file != '/assets/missing.png') {
            Upload.upload({
              url: '/settings/online_booking/' + data.id + '/upload',
              method: 'PUT',
              file: file
            }).progress(function (evt) {
              var progressPercentage = parseInt(100 * evt.loaded / evt.total);
            }).success(function (data, status, headers, config) {
              if (data.error) {
                $rootScope.errors = data.error;
                $rootScope.showMultyErrorToast();
                $rootScope.cloading = false;
              } 
              else {
                $translate('toast.bookingDataUpdated').then(function (msg) {
                  $rootScope.showSimpleToast(msg);
                });
                $scope.bookingData();
                $rootScope.cloading = false;
              }
            })
          } 
          else {
            $translate('toast.bookingDataUpdated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $scope.bookingData();
            $rootScope.cloading = false;
          }
        }
      });
    }
    $scope.booking_btn = true;
    $scope.facebook_content = false;
    $scope.embed_content = false;
    //remove page id of facebook
    $scope.remove_page_id = function (id) {
      $http.delete ('/settings/integrations/fb_page_remove?fb_page_id=' + id).success(function (results) {
        getFacebookPageId()
      })
    }
    $scope.open_booking_btn = function () {
      $scope.booking_btn = true;
      $scope.facebook_content = false;
      $scope.embed_content = false;
    }
    $scope.open_facebook_content = function () {
      $scope.booking_btn = false;
      $scope.facebook_content = true;
      $scope.embed_content = false;
    }
    $scope.open_embed_content = function () {
      $scope.booking_btn = false;
      $scope.facebook_content = false;
      $scope.embed_content = true;
    }
  }
]);

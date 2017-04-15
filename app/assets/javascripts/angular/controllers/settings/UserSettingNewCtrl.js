app.controller('UserSettingNewCtrl', [
  '$scope',
  '$rootScope',
  '$http',
  '$state',
  'Upload',
  '$translate',
  function($scope, $rootScope, $http, $state, Upload, $translate) {
    $rootScope.settingtopClasses1 = 'col-md-4 col-xs-4 top-links';
    $rootScope.settingtopClasses2 = 'col-md-8 col-xs-8 top-btn';
    $rootScope.showBlank = false;
    $rootScope.userBtnText = 'button.save';
    $rootScope.BtnSave = true;
   
    $scope.UserID = $rootScope.User_id;
    //Get Week Days
       var daynames = [
      {
        day: 'Sunday'
      },
      {
        day: 'Monday'
      },
      {
        day: 'Tuesday'
      },
      {
        day: 'Wednesday'
      },
      {
        day: 'Thursday'
      },
      {
        day: 'Friday'
      },
      {
        day: 'Saturday'
      }
    ]
    
    //Get Week Days
    function GetWeekDays(id) {
      var weekDays = []
      for (var i = 0; i < daynames.length; i++) {
        if (id == $rootScope.businessList[0].id) {
          var iss_selected = true;
        }
        if (daynames[i].day == 'Sunday' ||daynames[i].day == 'Saturday') {
          iss_selected = false;
        }
        weekDays.push({
          day_name:daynames[i].day,
          start_hr: '9',
          start_min: '0',
          end_hr: '17',
          end_min: '0',
          is_selected: iss_selected,
          practitioner_breaks_attributes: []
        })
      }
      return weekDays;
    }
    // Get Appoitment type
    function BindAppointmentTypes() {
      $http.get('/settings/user/appointment_types').success(function (list) {
        if (!list.code) {
          $scope.AppointmentTypes = list;
          getBlankUserData();
        }
      })
    }
    // Get blank User data
    function getBlankUserData() {
      $http.get('/settings/users/new').success(function (results) {
        if (results.user) {
          results.user.practi_info_attributes.appointment_services = $scope.AppointmentTypes
          $scope.rawuser = results.user;
          $scope.user = results.user;
          $scope.rawuser.role = 'scheduler';
          //$scope.rawuser.title = 'dr';
          $scope.rawuser.time_zone = $rootScope.commonData.time_zone;
          $scope.rawuser.practi_info_attributes.practi_refers_attributes[0].business_id = '13';
          $scope.rawuser.practi_info_attributes.appointment_services.unshift({
            name: 'N/A',
            appointment_type_id: 'N/A',
            is_selected: true
          });
          PushBusinessDays($scope.rawuser);
          $scope.user.practi_info_attributes.default_type = 'N/A';
        }
        else{
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
        }
      });
    }
    // Push Business Days 
    function PushBusinessDays(rawuser) {
      for (i = 0; i < $rootScope.businessList.length; i++) {
        rawuser.practi_info_attributes.practitioner_avails_attributes.push({
          business_id: $rootScope.businessList[i].id,
          business_name: $rootScope.businessList[i].name,
          days_attributes: GetWeekDays($rootScope.businessList[i].id)
        })
        $scope.user = rawuser;
      }
    }
    BindAppointmentTypes()
    // Add Practionar refer
    $scope.add_practi_refers = function (data) {
      $scope.bid = '' + data;
      $scope.user.practi_info_attributes.practi_refers_attributes.push({
        ref_type: '',
        number: '',
        business_id: $scope.bid
      });
    }
    // remove Practionar refer
    $scope.remove_practi_refers = function (data) {
      $scope.user.practi_info_attributes.practi_refers_attributes.splice(data, 1)
    }
    // Add break
    $scope.NewBreak = function (pindex, index) {
      $scope.user.practi_info_attributes.practitioner_avails_attributes[pindex].days_attributes[index].practitioner_breaks_attributes.push({
        start_hr: '10',
        start_min: '0',
        end_hr: '12',
        end_min: '0'
      });
    }
    // Remove break
    $scope.RemoveBreak = function (ppindex, pindex, index) {
      $scope.user.practi_info_attributes.practitioner_avails_attributes[ppindex].days_attributes[pindex].practitioner_breaks_attributes.splice(index, 1)
    }
    // Create New User
    // $scope.CreateUser = function (data) {
    //   console.log("+++++++++++Calling New function");
    //   console.log(data);
    //   if ($scope.user.is_doctor == false) {
    //     $scope.dummypractiinfo = angular.copy($scope.user.practi_info_attributes);
    //     $scope.user.practi_info_attributes = null;
    //   }
    //   if ($scope.user.is_doctor) {
    //     $scope.rawuser.practi_info_attributes.appointment_services.shift();
    //   }
    //   $rootScope.cloading = true;
    //   $http.post('/settings/users/', {
    //     user: data
    //   }).success(function (results) {
    //     if (results.error) {
    //       $rootScope.cloading = false;
    //       $rootScope.errors = results.error;
    //       $rootScope.showMultyErrorToast();
    //       // $scope.user.practi_info_attributes = $scope.dummypractiinfo
    //     } 
    //     else {
    //       $state.go('settings.users.info', {
    //         user_id: results.id
    //       })
    //       $scope.getUsersList();
    //       $rootScope.cloading = false;
    //       $rootScope.getBusinessList();
    //       $translate('toast.userDataCreated').then(function (msg) {
    //         $rootScope.showSimpleToast(msg);
    //       });
    //     }
    //   });
    // }

    //Create New User
    $scope.CreateUser = function (data, file) {
      if ($scope.user.is_doctor == false) {
        $scope.dummypractiinfo = angular.copy($scope.user.practi_info_attributes);
        $scope.user.practi_info_attributes = null;
      }
      if ($scope.user.is_doctor) {
        $scope.rawuser.practi_info_attributes.appointment_services.shift();
      }
      $rootScope.cloading = true;
      $http.post('/settings/users/', {
        user: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          // $scope.user.practi_info_attributes = $scope.dummypractiinfo
        }else if(results.flag == true){
          if(file != undefined){
          if (file.blobUrl != undefined) {
            $rootScope.cloading = true;
            Upload.upload({
              url: 'settings/users/' + results.id + '/upload',
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
                $state.go('settings.users.info',{'user_id': results.id},{reload: true});
                $translate('toast.userCreated').then(function (msg) {
                  $rootScope.showSimpleToast(msg);
                });
                $rootScope.cloading = false;
              }
            }).error(function (data, status, headers, config) {
            })
          }
          }else{
            $state.go('settings.users.info',{'user_id': results.id},{reload: true});
            $translate('toast.userCreated').then(function (msg) {
              $rootScope.showSimpleToast(msg);
            });
            $rootScope.cloading = false;
          }
        }
      });
    }

  }
]);

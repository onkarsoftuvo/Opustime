app.controller('UserProfileCtrl', [
  '$scope',
  '$location',
  '$rootScope',
  '$http',
  'filterFilter',
  'Data',
  '$stateParams',
  '$state',
  'Upload',
  '$translate',
  'GetWeekDays',
  
  function($scope, $location, $rootScope, $http, filterFilter, Data, $stateParams, $state, Upload, $translate, GetWeekDays) {
    /*var counter = 0;
    var acounter = 0;*/
    $rootScope.settingtopClasses1 = 'col-md-9 col-xs-6 top-links';
    $rootScope.settingtopClasses2 = 'col-md-3 col-xs-6 top-btn';
    $rootScope.showBlank = false;
    $rootScope.BtnSave = true;
    $rootScope.userBtnText = 'button.update';
    $scope.UserID = $rootScope.User_id;
 
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
    GetWeekDays.GetWeekDays();

    //Get timezones
    Data.getTimezone().then(function (results) {
      $scope.timezone = results.data;
    });

    // Get filtered Week Days Availability
    function GetFilteredWeekDays(avail_days) {
      var weekDays = [
      ];
      for (var i = 0; i < daynames.length; i++) {
        var dayNamefilter = daynames[i].day;
        var avali_days_array = filterFilter(avail_days, {
          day_name: dayNamefilter
        });
        if (avali_days_array.length > 0) {
          weekDays.push(avali_days_array[0]);
        } 
        else if (avali_days_array.length < 1) {
          weekDays.push({
            id: '',
            day_name: daynames[i].day,
            start_hr: '9',
            start_min: '0',
            end_hr: '17',
            end_min: '0',
            is_selected: false,
            practitioner_breaks_attributes: []
          })
        }
      }
      return weekDays;
    }
    // Appointment type binding
    function BindAppointmentTypes() {
      $rootScope.cloading = true;
      $http.get('/settings/user/appointment_types').success(function (list) {
        if (!list.code) {
          $scope.AppointmentTypes = list;
          getUserData();
        }
      })
    }

    BindAppointmentTypes();
    
    // Getting user Data 
    function getUserData() {
      $http.get('/settings/users/' + $stateParams.user_id + '/edit').success(function (results) {
        if (!results.code) {
          $rootScope.cloading = false;
          $scope.copyRowData = angular.copy(results)
          $scope.rawuser = results;
            console.log('rawuser ', results);
          $rootScope.u_id = results.id;
          $scope.rawuser.practi_info_attributes.appointment_services.unshift({
            name: 'N/A',
            appointment_type_id: 'N/A',
            is_selected: true
          });

          PushBusinessDays($scope.rawuser);
        }
        else{
          $rootScope.showErrorToast('Sorry you dont have permissions to access this page');
          $state.go('dashboard');
          $rootScope.cloading = false;
        }
      });
    }
    // practitioner_avails_attributes

    // pushing Business days(Day Availability)
    function PushBusinessDays(rawuser) {
      if (angular.isUndefined($rootScope.businessList)){
        Data.get('/settings/business').then(function (results) {
          $rootScope.businessList = results;
        });
      }else{
        for (i = 0; i < $rootScope.businessList.length; i++) {
        var businessId = '' + $rootScope.businessList[i].id;
        var practitioner_availablity = filterFilter(rawuser.practi_info_attributes.practitioner_avails_attributes, {
          business_id: businessId
        })
        if (practitioner_availablity.length < 1) {
          rawuser.practi_info_attributes.practitioner_avails_attributes.push({
            business_id: $rootScope.businessList[i].id,
            business_name: $rootScope.businessList[i].name,
            days_attributes: GetWeekDays.GetWeekDays()
          })
        } 
        else if (practitioner_availablity.length > 0) {
          practitioner_availablity[0].days_attributes =GetFilteredWeekDays(practitioner_availablity[0].days_attributes)
        }
        $scope.user = rawuser;
      }
      }
      $rootScope.cloading = false;
    }


    // Adding practioner reference
    $scope.add_practi_refers = function (data) {
      console.log('Add Number: ', data);
      var bid = '' + data;
        $scope.rawuser.practi_info_attributes.practi_refers_attributes.push({
        ref_type: '',
        number: '',
        business_id: bid
      })
    }

    // Remove practioner reference
    $scope.remove_practi_refers = function (data) {
      console.log('Remove Number: ', data);
      $scope.rawuser.practi_info_attributes.practi_refers_attributes.splice(data, 1);
    } 

    // Add Breaks 
    $scope.NewBreak = function (pindex, index) {
      $scope.user.practi_info_attributes.practitioner_avails_attributes[pindex].days_attributes[index].practitioner_breaks_attributes.push({
        start_hr: '10',
        start_min: '0',
        end_hr: '12',
        end_min: '0'
      });
    }

    // Remove breaks
    $scope.RemoveBreak = function (ppindex, pindex, index) {
      $scope.user.practi_info_attributes.practitioner_avails_attributes[ppindex].days_attributes[pindex].practitioner_breaks_attributes.splice(index, 1)
    }

    // Create new user
    // $scope.CreateUser = function (user) {
    //   $rootScope.cloading = true;
    //   $scope.rawuser.practi_info_attributes.appointment_services.shift();
    //   $http.put('/settings/users/' + $stateParams.user_id, {
    //     user: user
    //   }).success(function(results) {
    //     $scope.businessInfo = results.data;
    //     if (results.error) {
    //       $rootScope.cloading = false;
    //       $rootScope.errors = results.error;
    //       $rootScope.showMultyErrorToast();
    //     } 
    //     else {
    //       $rootScope.cloading = false;
    //       $translate('toast.userDataUpdated').then(function (msg) {
    //         $rootScope.showSimpleToast(msg);
    //       });
    //       //$scope.getUsersList();
    //       getUserData();
    //       $rootScope.cloading = false;
    //     }
    //   });
    // }

    //Update User
    $scope.CreateUser = function (data, file) {
      $scope.rawuser.practi_info_attributes.appointment_services.shift();
      $rootScope.cloading = true;
      $http.put('/settings/users/' + $stateParams.user_id,{
        user: data
      }).success(function (results) {
        if (results.error) {
          $rootScope.cloading = false;
          $rootScope.errors = results.error;
          $rootScope.showMultyErrorToast();
          // $scope.user.practi_info_attributes = $scope.dummypractiinfo
        }else if(results.flag == true){
          if (file != undefined || file.blobUrl != undefined) {
            $rootScope.cloading = true;
            Upload.upload({
              url: 'settings/users/' + data.id + '/upload',
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
                $translate('toast.settingsUpdated').then(function (msg) {
                    $('#current-user-name').text(results.username);
                  $rootScope.showSimpleToast(msg);
                });
                $rootScope.cloading = false;
              }
              }).error(function (data, status, headers, config) {
              })
            }else{
              $translate('toast.settingsUpdated').then(function (msg) {
                  $('#current-user-name').text(results.username);
                $rootScope.showSimpleToast(msg);
              });
              $rootScope.cloading = false;
            }
          }
        });
      }

    
   /* $rootScope.deleteuser = function () {
      $http.delete ('/settings/users/' + $stateParams.user_id).success(function (results) {
        if (results.flag == true) {
          $state.go('settings.users');
          $rootScope.showBlank = true;
        }
      });
    }*/

  }
]);

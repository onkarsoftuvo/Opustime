(function () {
  angular.module('onlineBooking').service('OB_service', OB_service);
  function OB_service($http, $q, config, $rootScope) {
    //service functions
    this.getBusinessList = getBusinessList;
    this.getServicesList = getServicesList;
    this.getPractitioners = getPractitioners;
    this.getCalAvailability = getCalAvailability;
    this.getCountry = getCountry;
    this.getCurrentCountry = getCurrentCountry;
    this.getCountryById = getCountryById;
    this.getState = getState;
    this.getStateList = getStateList;
    this.getMonthAvailability = getMonthAvailability;
    this.getDayAvailability = getDayAvailability;
    this.getBookingInfo = getBookingInfo;
    this.getServiceCategories = getServiceCategories;
    this.getBlankAppointment = getBlankAppointment;
    this.CreateAppointment = CreateAppointment;
    this.getAppointmentInfo = getAppointmentInfo;
    this.UpdateAppointment = UpdateAppointment;
    this.cancelAppointment = cancelAppointment;
    this.sendEmail = sendEmail;
    this.getProvience = getProvience;
    //internal objects and variables
    var url = ''
    if (config.port != '') {
      url = config.url + ':' + config.port;
    }
    //var comp_name = '?comp_name=Bedminton';
    var comp_name = location.search;
    if(comp_name == "" || comp_name == null) {
      var comp_name = '?'+ location.hash.split('?')[1];
    }

    var countries = [];
    $http.get('assets/angular/common/countries.json').then(function (results) {
      var d = results
      localStorage.setItem('countries', JSON.stringify(results.data));
    })
    //getting booking info
    function getBookingInfo() {
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/info' + comp_name).then(function (data) {
          return resolve(data)
        })
      })
    }
    //getting business list
    function getBusinessList() {
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/locations' + comp_name).then(function (data) {
          return resolve(data)
        })
      })
    }
    //getting appointment types
    function getServicesList(buisnessId) {
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/' + buisnessId + '/services' + comp_name).then(function (data) {
          return resolve(data)
        })
      })
    }
    //getting services categories
    function getServiceCategories(services) {
      return $q(function (resolve, reject) {
        var categorylist = [];
        services.forEach(function (service) {
          if (service.category != null && service.category != undefined && service.category != '') {
            categorylist.push(service.category)
          }
        })
      });
    }
    //getting practitioners types
    function getPractitioners(businessId, serviceId) {
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/' + businessId + '/services/' + serviceId + '/practitioners' + comp_name).then(function (data) {
          return resolve(data)
        })
      })
    }
    //getting Calendar Availability
    function getCalAvailability(buisnessId) {
      return $q(function (resolve, reject) {
        return $http.get(url + '/settings/appointment_type').then(function (data) {
          return resolve(data)
        })
      })
    }
    //getting theme class
    function getThemeClass() {
      $http.get(url + '/booking/color_option' + comp_name).success(function (data) {
        $rootScope.getTheme = data;
      })
    }
    getThemeClass();
    //get month availability
    function getMonthAvailability(businessId, practitionerId, servicesId, date, comp) {
      if (!comp_name) {
        comp_name = '?'+comp;
      }
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/' + businessId + '/practitioners/' + practitionerId + '/' + servicesId + '/availability' + comp_name + '&m=' + (date.month() + 1) + '&y=' + date.year()).then(function (data) {
          return resolve(data)
        })
      })
    }
    //get day availability
    function getDayAvailability(businessId, practitionerId, servicesId, date) {
      return $q(function (resolve, reject) {
        return $http.get(url + '/booking/specific_date/' + businessId + '/practitioners/' + practitionerId + '/' + servicesId + '/availability' + comp_name + '&m=' + (date.month() + 1) + '&y=' + date.year() + '&d=' + date.date()).then(function (data) {
          console.log(data);
          return resolve(data)
        })
      })
    }
    //create appointment
    function CreateAppointment(data) {
      return $q(function (resolve, reject) {
        return $http.post(url + '/appointments/booking' + comp_name, data).then(function (data) {
          return resolve(data)
        })
      })
    }
    //update appointment
    function UpdateAppointment(data) {
      return $q(function (resolve, reject) {
        return $http.put(url + '/appointments/' + data.appointment.id + '/booking/partial/update' + comp_name, data).then(function (data) {
          return resolve(data)
        })
      })
    }
    //send email
    function sendEmail(appointmentId, data) {
      return $q(function (resolve, reject) {
        return $http.post(url + '/booking/appointments/' + appointmentId + '/patient/send_email', data).then(function (data) {
          return resolve(data.data)
        })
      })
    }
    //get provience
    function getProvience(data){
      return $q(function(resolve, reject){
        return $http.get(url + '/booking/patient_country_info', data).then(function(result){
          return resolve(result);
        })
      });
    }
    //cancel appointment
    function cancelAppointment(data, id) {
      return $q(function (resolve, reject) {
        return $http.put(url + '/appointments/' + id + '/booking/partial/update' + comp_name, data).then(function (data) {
          return resolve(data)
        })
      })
    }
    //creating blank appointment
    function getBlankAppointment() {
      return {
        'appointment': {
          'end_hr': '',
          'end_min': '',
          'user_id': '',
          'appnt_date': '',
          'repeat_by': null,
          'repeat_start': null,
          'start_hr': '',
          'start_min': '',
          'appointment_type_id': '',
          'new_patient': {
            'title': '',
            'contact_type': 'mobile',
            'reminder_type': 'email',
            'gender': '',
            'first_name': '',
            'last_name': '',
            'dob': '',
            'contact_no': '',
            'email': ''
          },
          'notes': '',
          'repeat_end': null,
          'business_id': '',
          'week_days': []
        }
      }
    }
    //getting appointment info
    function getAppointmentInfo(appointmentId) {
      return $q(function (resolve, reject) {
        return $http.get(url + '/appointments/' + appointmentId + '/booking').then(function (data) {
          return resolve(data)
        })
      })
    }
    function getCountry() {
      return $q(function (resolve, reject) {
        if (localStorage.countries) {
          var a = JSON.parse(localStorage.countries) //return a
          return resolve(a)
        }
        else {
          return $http.get('assets/angular/common/countries.json').then(function (results) {
            var d = results
            return resolve(results.data)
            localStorage.setItem('countries', JSON.stringify(results.data));
          })
        }
      })
    }
    function getCurrentCountry() {
      return $q(function (resolve, reject) {
        return $http.get('http://ipinfo.io/json').then(function (results) {
          return resolve(results.data)
        })
      })
    }
    function getCountryById(id) {
      return $q(function (resolve, reject) {
        return getCountry().then(function (results) {
          var result = results.filter(function (c) {
            return c.code === id;
          }) [0].name;
          return resolve(result)
        });
      });
    };
    function getStateList(filename) {
      return $q(function (resolve, reject) {
        return $http.get('assets/angular/common/countries/' + filename + '.json').then(function (results) {
          return resolve(results.data)
        });
      });
    }
    function getState(filename, stateId) {
      return $q(function (resolve, reject) {
        return $http.get('assets/angular/common/countries/' + filename + '.json').then(function (results) {
          var result = results.data.filter(function (c) {
            return c.code === stateId;
          }) [0].name;
          return resolve(result)
        });
      });
    }
  }
}) ();

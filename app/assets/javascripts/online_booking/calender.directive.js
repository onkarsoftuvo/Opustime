var app = angular.module('onlineBooking')
app.directive('calendar', function (OB_service, $stateParams) {
  return {
    restrict: 'E',
    templateUrl: 'assets/online_booking/calender.html',
    scope: {
      selected: '=',
      checked: '=',
      dayavailability: '=',
    },
    link: function (scope) {
      scope.selected = scope.selected || moment();
      if (scope.checked != undefined && scope.checked != null && scope.checked != '') {
        scope.checked = _removeTime(scope.checked);
      }      
      
      //scope.checked = _removeTime(scope.checked);

      scope.month = scope.selected.clone();
      scope.MonthAvailability = [];
      var start = scope.selected.clone();
      start.date(1);
      _removeTime(start.day(0));
      scope.select = function (day) {
        //scope.checked = _removeTime(scope.checked);
        scope.$parent.$parent.slowLoad = true;
        scope.checked = day.date.hour(0).minute(0).second(0).millisecond(0);
        businessId = localStorage.OB_businessId
        servicesId = localStorage.OB_servicesId
        practitionerId = localStorage.OB_practitionerId
        OB_service.getDayAvailability(businessId, practitionerId, servicesId, day.date).then(function (results) {
          scope.dayavailability = results.data
          scope.$parent.$parent.slowLoad = false;
          /*scope.slowLoad = false;
          scope.$apply(function(){
          scope.dayavailability = results.data
          })*/
        })
      };
      function initialmonth() {
        if ($stateParams.appointmentId != undefined) {
          OB_service.getAppointmentInfo($stateParams.appointmentId).then(function (results) {
            businessId = results.data.business_info.id
            servicesId = results.data.service_info.id;
            practitionerId = results.data.doctor_info.id;
            localStorage.setItem('OB_businessId', businessId)
            localStorage.setItem('OB_servicesId', servicesId)
            localStorage.setItem('OB_practitionerId', practitionerId)
            var cday = {
              date: moment(results.data.appnt_date_sc)
            }
            scope.selected = _removeTime(cday.date.clone());
            scope.month = scope.selected.clone();
            start = scope.month.clone();
            start.date(1);
            _removeTime(start.day(0));
            OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (result) {
              scope.MonthAvailability = result.data.availability
              scope.select(cday)
              _buildMonth(scope, start, scope.month);
            })
          })
        } 
        else {
          businessId = localStorage.OB_businessId
          servicesId = localStorage.OB_servicesId
          practitionerId = localStorage.OB_practitionerId
          OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (results) {
            scope.MonthAvailability = results.data.availability
            _buildMonth(scope, start, scope.month);
          })
        }        
        // _buildMonth(scope, start, scope.month);
      }
      initialmonth()
      scope.next = function () {
        var next = scope.month.clone();
        _removeTime(next.month(next.month() + 1).date(1));
        scope.month.month(scope.month.month() + 1);
        scope.$parent.$parent.slowLoad = true;
        if ($stateParams.appointmentId != undefined) {
          OB_service.getAppointmentInfo($stateParams.appointmentId).then(function (results) {
            businessId = results.data.business_info.id
            servicesId = results.data.service_info.id;
            practitionerId = results.data.doctor_info.id;
            localStorage.setItem('OB_businessId', businessId)
            localStorage.setItem('OB_servicesId', servicesId)
            localStorage.setItem('OB_practitionerId', practitionerId)
            OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (results) {
              scope.MonthAvailability = results.data.availability
              _buildMonth(scope, next, scope.month);
              scope.$parent.$parent.slowLoad = false;
            })
          })
        } 
        else {
          businessId = localStorage.OB_businessId
          servicesId = localStorage.OB_servicesId
          practitionerId = localStorage.OB_practitionerId
          OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (results) {
            scope.MonthAvailability = results.data.availability
            _buildMonth(scope, next, scope.month);
            scope.$parent.$parent.slowLoad = false;
          })
        }
      };
      scope.previous = function () {
        var previous = scope.month.clone();
        _removeTime(previous.month(previous.month() - 1).date(1));
        scope.month.month(scope.month.month() - 1);
        /*businessId = localStorage.OB_businessId
        servicesId = localStorage.OB_servicesId
        practitionerId = localStorage.OB_practitionerId
        OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function(results){
            scope.MonthAvailability = results.data.availability
            _buildMonth(scope, previous, scope.month);
        })*/
        scope.$parent.$parent.slowLoad = true;
        if ($stateParams.appointmentId != undefined) {
          OB_service.getAppointmentInfo($stateParams.appointmentId).then(function (results) {
            businessId = results.data.business_info.id
            servicesId = results.data.service_info.id;
            practitionerId = results.data.doctor_info.id;
            localStorage.setItem('OB_businessId', businessId)
            localStorage.setItem('OB_servicesId', servicesId)
            localStorage.setItem('OB_practitionerId', practitionerId)
            OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (results) {
              scope.MonthAvailability = results.data.availability
              _buildMonth(scope, previous, scope.month);
              scope.$parent.$parent.slowLoad = false;
            })
          })
        } 
        else {
          businessId = localStorage.OB_businessId
          servicesId = localStorage.OB_servicesId
          practitionerId = localStorage.OB_practitionerId
          OB_service.getMonthAvailability(businessId, practitionerId, servicesId, scope.month).then(function (results) {
            scope.MonthAvailability = results.data.availability
            _buildMonth(scope, previous, scope.month);
            scope.$parent.$parent.slowLoad = false;
          })
        }
      };
    }
  };
  function _removeTime(date) {
    return date.day(0).hour(0).minute(0).second(0).millisecond(0);
  }
  function _buildMonth(scope, start, month) {
    scope.weeks = [];
    var done = false,
    date = start.clone(),
    monthIndex = date.month(),
    count = 0;
    while (!done) {
      scope.weeks.push({
        days: _buildWeek(scope, date.clone(), month)
      });
      date.add(1, 'w');
      done = count++ > 2 && monthIndex !== date.month();
      monthIndex = date.month();
    }
  }
  function _buildWeek(scope, date, month) {
    var days = [
    ];
    for (var i = 0; i < 7; i++) {
      days.push({
        name: date.format('dd').substring(0, 1),
        number: date.date(),
        isCurrentMonth: date.month() === month.month(),
        isToday: date.isSame(new Date(), 'day'),
        date: date,
        isavail: isavail(scope, date)
      });
      date = date.clone();
      date.add(1, 'd');
    }
    return days;
  }
  function isavail(scope, date) {
    var isavail = false
    if (scope.MonthAvailability.length > 0) {
      scope.MonthAvailability.forEach(function (avail) {
        if (avail.date == date.format('YYYY-MM-DD')) {
          if (avail.time_slots.morning_flag || avail.time_slots.afternoon_flag || avail.time_slots.evening_flag) {
            isavail = true;
          }          
          /*else{
            isavail= false
          }*/
        }
      })
      return isavail
    }
  }
})

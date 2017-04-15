app.factory('appointmentServe', [
  '$http',
  '$q',
  '$filter',
  function ($http, $q, $filter) {
    var obj = {};
    obj.getEvents = function (bid, doctors, startDate, endDate, patient_arrival, patient_not_arrival, invoice_paid, outstanding_invoice, tr_note_final, tr_note_draft, appnt_complete, appnt_pending, appnt_future, no_appnt_future, currentView) {
      var path = '/appointments/' + bid + '/time-specific?doctors=' + doctors + '&start_date=' + startDate + '&end_date=' + endDate + '&patient_arrival=' + patient_arrival + '&patient_not_arrival=' + patient_not_arrival + '&invoice_paid=' + invoice_paid + '&outstanding_invoice=' + outstanding_invoice + '&tr_note_final=' + tr_note_final + '&tr_note_draft=' + tr_note_draft + '&appnt_complete=' + appnt_complete + '&appnt_pending=' + appnt_pending + '&appnt_future=' + appnt_future + '&no_appnt_future=' + no_appnt_future;
      return $q(function (resolve) {
        var events = [];
        return $http.get(path).then(function (results) {
          results.data.appointments.forEach(function (appointment) {
            events.push({
              id: appointment.id,
              className:''+appointment.id,
              title: appointment.title,
              start: new Date(appointment.start),
              end: new Date(appointment.end),
              color: appointment.color_code,
              resourceId: appointment.resourceId,
              appointment_type_name: appointment.appointment_type_name,
              docter: appointment.practitioner_name,
              Patient_Id: appointment.patient_id,
              total_duration: appointment.appnt_time_period,
              patient_arrive: appointment.patient_arrive,
              appnt_status: appointment.appnt_status,
              profile_pic:  appointment.profile_pic,
              profile_pic_flag:  appointment.profile_pic_flag,
              associated_treatment_note: appointment.associated_treatment_note,
              associated_treatment_note_status: appointment.associated_treatment_note_status,
              associated_invoice_status: appointment.associated_invoice_status,
              is_notes_avail: appointment.is_notes_avail,
              patient_gender: appointment.patient_gender,
              is_cancel: appointment.is_cancel,
              patient_arrive: appointment.patient_arrive,
              appnt_status: appointment.appnt_status,
              online_booked: appointment.online_booked,
              reference_number: appointment.reference_number
            })
          })
          return obj.getUnAvailability(bid, doctors, currentView, startDate, endDate).then(function (data) {
            events = events.concat(data)
            return resolve(events);
          })
          //return resolve(events);
        });
      });
    };
    function addCollon(value) {
      var a = value.split('.')
      a = addZero(a[0]) + ':' + a[1];
      return a;
    }
    function addZero(i) {
      if (i < 10) {
        i = '0' + i;
      }
      return i;
    }
    obj.getUnAvailability = function (bid, doctor, currentView, startDate, endDate) {
      return $q(function (resolve) {
        var UnAvailability = [
        ]
        var AvailabilityAvail = [
        ]
        var calenderMin = localStorage.getItem('savedMinTime')
        var calenderMax = localStorage.getItem('savedMaxTime')
        var calenderMin = parseFloat(calenderMin.replace(':', '.')).toFixed(2);
        var calenderMax = parseFloat(calenderMax.replace(':', '.')).toFixed(2);
        return $http.get('/appointments/' + bid + '/practitioners/availabilities?doctors=' + doctor + '&start_date=' + startDate + '&end_date=' + endDate).then(function (results) {
          results.data.practitioners_availability_info.forEach(function (practi) {
            if (practi.unavailable_block.length > 0) {
              practi.unavailable_block.forEach(function (unavailability) {
                UnAvailability.push({
                  id: unavailability.id,
                  title: 'unavailable',
                  end: unavailability.one_off_end,
                  start: unavailability.one_off_start,
                  resourceId: practi.id,
                  color: '#333',
                  app_indication: '_un_app'
                });
              })
            }
            practi.out_of_service_time.forEach(function (avail, i) {
              avail.time_range.forEach(function (days) {
                days.start_time = days.start_time.split(':')
                days.end_time = days.end_time.split(':')
                AvailabilityAvail.push({
                  id: 1,
                  start: addZero(days.start_time[0]) + ':' + addZero(days.start_time[1]),
                  end: addZero(days.end_time[0]) + ':' + addZero(days.end_time[1]),
                  rendering: 'background',
                  color: '#666',
                  resourceId: practi.id,
                  dow: [
                    i
                  ]
                })
              })
            })
          });
          var userAvail = AvailabilityAvail.concat(UnAvailability)
          return resolve(userAvail)
        })
      })
    }
    return obj;
  }
]);

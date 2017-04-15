app.factory('GetWeekDays', function() {
            var GetWeekDays = {};
            
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
    GetWeekDays.GetWeekDays = function () {
      var weekDays = [
      ]
      for (var i = 0; i < daynames.length; i++) {
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
      return weekDays;
    }
            return GetWeekDays;
         });
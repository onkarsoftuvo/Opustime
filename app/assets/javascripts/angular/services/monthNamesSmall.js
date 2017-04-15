app.factory('monthNameServiceSmall', function() {
   var monthName = {};
   monthName.month = function(d) {
	var month = new Array();
	month[0] = "Jan";
	month[1] = "Feb";
	month[2] = "Mar";
	month[3] = "Apr";
	month[4] = "May";
	month[5] = "Jun";
	month[6] = "Jul";
	month[7] = "Aug";
	month[8] = "Sep";
	month[9] = "Oct";
	month[10] = "Nov";
	month[11] = "Dec";
      return month[d];
   }
   return monthName;
});
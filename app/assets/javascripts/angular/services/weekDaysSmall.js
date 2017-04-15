app.factory("weekServiceSmall", ['$http',function ($http) { 
	var weekDay = {};
   	weekDay.week = function(d) {
		var weekday = new Array(7);
		weekday[0]=  "SUN";
		weekday[1] = "MON";
		weekday[2] = "TUE";
		weekday[3] = "WED";
		weekday[4] = "THU";
		weekday[5] = "FRI";
		weekday[6] = "SAT";
	    return weekday[d];
	}
   return weekDay;
}]);
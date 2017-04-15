app.factory('toplink', ['$http', function ($http) {
    var obj = {};
    obj.getTopLink = function () {
      return $http.get('assets/angular/common/top_links.json').then(function (results) {
        return results.data;
        console.log(results);
      });
    };
    return obj;
  }
]);

app.service('pageService', function () {
	var paging = {};
	return {
	    getPaging: function () {
	        return paging;
	    },
	    setPaging: function (value) {
	        paging = value;
	    }
	};

});

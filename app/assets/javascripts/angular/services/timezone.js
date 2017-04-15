app.factory('Data', ['$http', function ($http) {
    var obj = { };
    obj.getTimezone = function () {
        return $http.get('/timezones').then(function (results) {
          return results.data;
      });
    };
    obj.getCountry = function () {
      return $http.get('assets/angular/common/countries.json').then(function (results) {
        return results.data;
      });
    };
    obj.getCurrentCountry = function () {
      return $http.get('http://ipinfo.io/json').then(function (results) {
        return results.data;
      });
    }
    obj.get = function (q) {
      return $http.get(q).then(function (results) {
        return results.data;
      });
    }
    obj.put = function (q) {
      return $http.put(q).then(function (results) {
        return results.data;
      });
    }
    return obj;
  }
]);

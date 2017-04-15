app.factory('Auth', ['$http', function ($http) {
    var obj = {};
    obj.getsession = function () {
      return $http.get('/getsession').then(function (results) {
        return results.data;
      });
    };
    obj.getAuthorised = function () {
      return $http.get('/dashboard/modules').then(function (results) {
        return results.data;
      });
    }
    return obj;
  }
]);

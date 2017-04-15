var myApp = angular.module('myapplication', ['ngRoute', 'ngResource']);
	myApp.factory('Users', ['$resource',function($resource){
	 return $resource('/users.json', {}, {
	 query: { method: 'GET', isArray: true },
	 create: { method: 'POST' }
	 });
	}]);
	 
	myApp.factory('User', ['$resource', function($resource){
	 return $resource('/users/:id.json', {}, {
	 show: { method: 'GET' },
	 update: { method: 'PUT', params: {id: '@id'} },
	 delete: { method: 'DELETE', params: {id: '@id'} }
	 });
	}]);
	
	myApp.config([
      '$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
      $routeProvider.when('/users',{
         templateUrl: '/templates/users/index.html',
         controller: 'UserListCtr'
      });
      $routeProvider.when('/users/new', {
        templateUrl: '/templates/users/new.html',
        controller: 'UserAdd Ctr'
      });
      $routeProvider.when('/users/:id/edit', {
        templateUrl: '/templates/users/edit.html',
        controller: "UserUpdateCtr"
      });
      $routeProvider.otherwise({
        redirectTo: '/users'
      });
      }
    ]);
	
	myApp.controller("UserListCtr", ['$scope', '$resource', 'Users', 'User', '$location', function($scope, $resource, Users, User, $location) {
	  $scope.users = Users.query(); //it's getting user collection
	}]);
	
	myApp.controller("UserUpdateCtr", ['$scope', '$resource', 'User', '$location', '$routeParams', function($scope, $resource, User, $location, $routeParams) {
	   $scope.user = User.get({id: $routeParams.id});
	   $scope.update = function(){
	     if ($scope.userForm.$valid){
	       User.update($scope.user,function(){
	         $location.path('/');
	       }, function(error) {
	         console.log(error);
	      });
	     }
	   };
	}]);
	
	myApp.controller("UserListCtr", ['$scope', '$http', '$resource', 'Users', 'User', '$location', function($scope, $http, $resource, Users, User, $location) {
	  $scope.users = Users.query();
	  $scope.deleteUser = function (userId) {
	    if (confirm("Are you sure you want to delete this user?")){
	      User.delete({ id: userId }, function(){
	        $scope.users = Users.query();   // after delete user get users collection.
	        $location.path('/');
	      });
	    }
	  };
	}]);

    
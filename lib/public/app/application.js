var regenwolkeManager = angular.module('regenwolkeManager', ['ngRoute','ui.bootstrap']).run(function($rootScope,$location,RegenwolkeManager) {
  
  $rootScope.returnToPath = $location.path();

  $rootScope.$watch('loggedIn', function(newValue, oldValue) {
    if (newValue) {
      $location.path('/');
    }
  });
  $location.path('/log_in');

  RegenwolkeManager.logInUsingLocalStorageToken().success(function() {
    RegenwolkeManager.setToken(localStorage.getItem('jwt-token'));
    $rootScope.loggedIn = true;
  });

});

regenwolkeManager.config(function($routeProvider) {
  $routeProvider.when('/log_in', {
    controller: 'LogInController',
    templateUrl: 'log_in_template'
  });

  $routeProvider.when('/', {
    controller: 'LogInController',
    templateUrl: 'status_template'
  });


});

regenwolkeManager.service('RegenwolkeManager', function($http) {

  this.logIn = function(username, password) {
    return $http.post('log_in', {username: username, password: password});
  }

  this.setToken = function(token) {
    $http.defaults.headers.common['Authorization'] = 'Bearer '+token;
    localStorage.setItem('jwt-token', token);
  }

  this.logInUsingLocalStorageToken = function() {
    var token = localStorage.getItem('jwt-token');
    $http.defaults.headers.common['Authorization'] = 'Bearer '+token;
    return $http.get("username");
  }  

});


regenwolkeManager.controller('PageController', function($scope, $location) {

});

regenwolkeManager.controller('LogInController',function($scope, $rootScope, RegenwolkeManager) {


  $scope.logIn = function() {
    RegenwolkeManager.logIn($scope.adminUsername, $scope.adminPassword).success(function(data, status, headers, config) {

      $rootScope.loggedIn = true;
      RegenwolkeManager.setToken(data);
    });
  };

});


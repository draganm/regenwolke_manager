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

  $routeProvider.when('/services', {
    controller: 'ServicesController',
    templateUrl: 'services_template'
  });

});


regenwolkeManager.service('RegenwolkeManager', function($http) {

  this.logIn = function(username, password) {
    return $http.post('log_in', {username: username, password: password});
  }

  this.applications = function() {
    return $http.get('applications');
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

  this.createServiceInstance = function(serviceId, instanceName) {
    return $http.post('/services/'+serviceId, {name: instanceName});
  }

  this.getServiceNames = function(serviceId) {
    return $http.get('/services/'+serviceId)
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

  $scope.logOut = function() {
    alert('log out?');
    $rootScope.loggedIn = false;
    RegenwolkeManager.setToken(null);
  }


});


regenwolkeManager.controller('NavigationController',function($scope, $rootScope, $location, RegenwolkeManager) {

  $scope.logOut = function() {
    $rootScope.loggedIn = false;
    RegenwolkeManager.setToken(null);
    $location.path('/log_in');
  }

});

regenwolkeManager.controller('ApplicationListController', function($scope, RegenwolkeManager) {

  $scope.applications = [];

  RegenwolkeManager.applications().success(function(data, status, headers, config) {
    $scope.applications = data;
  });

});

regenwolkeManager.controller('ServicesController', function($scope, RegenwolkeManager) {

  $scope.services = [{
    name: 'PostgreSQL',
    service_id: 'postgresql'
  }];



});

regenwolkeManager.controller('ServiceController', function($scope, RegenwolkeManager) {

  $scope.serviceId = $scope.service.service_id;

  $scope.serviceInstances = [
  ];

  $scope.createInstance = function() {
    console.log('about to create '+$scope.serviceId);
    RegenwolkeManager.createServiceInstance($scope.serviceId, $scope.instanceName);
    $scope.instanceName = '';
    $scope.fetchInstances();
  }

  $scope.fetchInstances = function() {
    RegenwolkeManager.getServiceNames($scope.serviceId).success(function(data){
      $scope.serviceInstances = data;
    });
  }

  $scope.fetchInstances();

})



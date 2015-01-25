var regenwolkeManager = angular.module('regenwolkeManager', ['ngRoute','ui.bootstrap']).run(function($rootScope,$location) {
  $rootScope.returnToPath = $location.path();

  $rootScope.$watch('loggedIn', function(newValue, oldValue) {
    if (newValue) {
      console.log('switching to '+$rootScope.returnToPath);
      $location.path($rootScope.returnToPath);
    }
  });
  $location.path('/log_in');
  // $rootScope.$watch("loggedInUsername", function(newUsername, oldUsername) {

  //   $location = '/log_in'
  // });
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

  // $routeProvider.when('/installation_details', {
  //   controller: 'InstallationDetailsController',
  //   templateUrl: 'installation_details'
  // });  
  // $routeProvider.when('/installation_status', {
  //   controller: 'InstallationStatusController',
  //   templateUrl: 'installation_status'
  // });  
});

regenwolkeManager.service('RegenwolkeManager', function($http) {

  this.logIn = function(username, password) {
    return $http.post('log_in', {username: username, password: password});
  }

  this.setToken = function(token) {
    $http.defaults.headers.common['Authorization'] = 'Bearer '+token;
    localStorage.setItem('jwt-token', token);
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




// regenwolkeManager.controller('InstallationDetailsController', function($scope, Installer, usSpinnerService, $location) {
//   $scope.availableRegionsAndSizes = [];

//   $scope.selectedRegionIndex = null;
//   $scope.availableSizes = [];

//   $scope.$watch('selectedRegionIndex', function() {
//     var region=$scope.availableRegionsAndSizes[parseInt($scope.selectedRegionIndex)];
//     if (region) {
//       $scope.availableSizes=region.sizes;
//       $scope.selectedRegion=region.slug;
//     }
//   });

//   Installer.availableRegionsAndSizes().success(function(data) {
//     $scope.availableRegionsAndSizes = data;
//   });

//   $scope.submit = function() {
//     Installer.startInstallation($scope.selectedRegion, $scope.selectedSize, $scope.hostname, $scope.adminPassword).success( function() {
//       $location.path('/installation_status');
//     }).error(function() {
//       alert("failed");
//     });

//   }
// });

// regenwolkeManager.controller('InstallationStatusController', function($scope, Installer, $location, $timeout) {
//   $scope.currentStatus = {current_step: '', complete: 0};


//   $scope.intervalFunction = function() {
//     $timeout(function() {
//       Installer.currentInstallationStatus().success(function(data) {
//         $scope.currentStatus = data;
//       });
//       $scope.intervalFunction();
//     }, 1000);
//   };

//   $scope.intervalFunction();

// });
var regenwolkeInstaller = angular.module('regenwolkeManager', ['ngRoute','ui.bootstrap']);

// regenwolkeInstaller.config(function($routeProvider) {
//   $routeProvider.when('/', {
//     controller: 'CredentialsController',
//     templateUrl: 'provider_credentials'
//   });
//   $routeProvider.when('/installation_details', {
//     controller: 'InstallationDetailsController',
//     templateUrl: 'installation_details'
//   });  
//   $routeProvider.when('/installation_status', {
//     controller: 'InstallationStatusController',
//     templateUrl: 'installation_status'
//   });  
// });

// regenwolkeInstaller.service('Installer', function($http) {

//   this.checkDigitalOceanToken = function(token) {
//     return $http.post('check_digital_ocean_token',{'token': token});
//   }

//   this.availableRegionsAndSizes = function() {
//     return $http.get('available_regions_and_sizes');
//   }

//   this.startInstallation = function(region, size, host_name, admin_password) {
//     return $http.post('start_installation', {region: region, size: size, host_name: host_name, admin_password: admin_password}); 
//   }

//   this.currentInstallationStatus = function() {
//     return $http.get('current_installation_status');
//   }

// });


// regenwolkeInstaller.controller('CredentialsController', function($scope, Installer, usSpinnerService, $location) {
//   $scope.token=''
//   $scope.waitingForApi=false;
//   $scope.submit = function() {
//     $scope.waitingForApi = true;
//     usSpinnerService.spin('check-token-spinner');
//     Installer.checkDigitalOceanToken($scope.token).success(function() {
//       usSpinnerService.stop('check-token-spinner');
//       $scope.waitingForApi = false;
//       $location.path('/installation_details');
//     }).error(function() {
//       usSpinnerService.stop('check-token-spinner');
//       $scope.waitingForApi = false;
//     });
//   }
// });

// regenwolkeInstaller.controller('InstallationDetailsController', function($scope, Installer, usSpinnerService, $location) {
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

// regenwolkeInstaller.controller('InstallationStatusController', function($scope, Installer, $location, $timeout) {
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
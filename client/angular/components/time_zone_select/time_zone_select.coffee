AppConfig   = require 'shared/services/app_config'
EventBus    = require 'shared/services/event_bus'
TimeService = require 'shared/services/time_service'
I18n        = require 'shared/services/i18n'

angular.module('loomioApp').directive 'timeZoneSelect', ->
  scope: {zone: '='}
  restrict: 'E'
  templateUrl: 'generated/components/time_zone_select/time_zone_select.html'
  replace: true
  controller: ['$scope', ($scope) ->
    $scope.zone = $scope.zone || AppConfig.timeZone
    $scope.timezoneKey = null || (_.invert(AppConfig.timeZones))[AppConfig.timeZone]

    $scope.names = ->
      _.keys(AppConfig.timeZones).sort()

    $scope.selectChanged = ->
      $scope.zone = AppConfig.timeZones[$scope.timezoneKey]
      EventBus.emit $scope, 'timeZoneSelected', $scope.zone
  ]

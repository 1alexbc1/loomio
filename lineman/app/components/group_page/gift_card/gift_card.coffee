angular.module('loomioApp').directive 'giftCard', ->
  scope: {group: '='}
  restrict: 'E'
  templateUrl: 'generated/components/group_page/gift_card/gift_card.html'
  replace: true
  controller: ($scope, $window, AppConfig) ->

    $scope.makeDonation = ->
      $window.open "#{AppConfig.chargify.donation_url}?#{encodedChargifyParams()}", '_blank'
      true

    encodedChargifyParams = ->
      params =
        first_name: CurrentUser.firstName()
        last_name: CurrentUser.lastName()
        email: CurrentUser.email
        organization: $scope.group.name
        reference: $scope.group.key

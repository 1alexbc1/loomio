angular.module('loomioApp').directive 'positionButtonsPanel', ->
  scope: {proposal: '='}
  restrict: 'E'
  templateUrl: 'generated/components/thread_page/position_buttons_panel/position_buttons_panel.html'
  replace: true
  controller: ($scope, ModalService, VoteForm, CurrentUser, Records) ->

    $scope.undecided = ->
      !($scope.proposal.lastVoteByUser(CurrentUser)?)

    $scope.select = (position) ->
      ModalService.open(VoteForm, vote: -> Records.votes.build(proposal_id: $scope.proposal.id, position: position))

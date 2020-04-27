angular.module('loomioApp').factory 'PollPollForm', ->
  templateUrl: 'generated/components/poll/poll/form/poll_poll_form.html'
  controller: ($scope, poll, FormService, KeyEventService, TranslationService) ->
    $scope.poll = poll.clone()
    $scope.poll.makeAnnouncement = $scope.poll.isNew()

    actionName = if $scope.poll.isNew() then 'created' else 'updated'

    $scope.poll.pollOptionsAttributes = _.map $scope.poll.pollOptions(), (option) ->
      {id: option.id, name: option.name}

    TranslationService.eagerTranslate $scope,
      titlePlaceholder:     'poll_poll_form.title_placeholder'
      detailsPlaceholder:   'poll_poll_form.details_placeholder'
      addOptionPlaceholder: 'poll_poll_form.add_option_placeholder'

    $scope.addOption =  ->
      return unless $scope.newOptionName
      $scope.poll.pollOptionsAttributes.push
        name: $scope.newOptionName
      $scope.newOptionName = ''

    $scope.removeOption = (option) ->
      $scope.pollOptionsAttributeFor(option.name)._destroy = true

    $scope.pollOptionsAttributeFor = (name) ->
      _.find($scope.poll.pollOptionsAttributes, (attrs) -> name == attrs.name) or {}

    $scope.submit = FormService.submit $scope, $scope.poll,
      flashSuccess: "poll_poll_form.messages.#{actionName}"
      draftFields: ['title', 'details']
      prepareFn: $scope.addOption

    KeyEventService.submitOnEnter($scope)
    KeyEventService.registerKeyEvent $scope, 'pressedEnter', $scope.addOption, (active) ->
      active.classList.contains('poll-poll-form__add-option-input')
